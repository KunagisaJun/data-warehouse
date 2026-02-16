using System;
using System.Collections.Generic;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace DocuGen
{
    internal static class ScriptDomColumnDataflowExtractor
    {
        public static void Enrich(Catalog cat, Dictionary<string, List<string>> sqlFilesByDb)
        {
            foreach (var kv in sqlFilesByDb)
            {
                var currentDb = NameNorm.NormalizeDb(kv.Key);

                foreach (var file in kv.Value)
                {
                    var frag = SqlDomParse.ParseFile(file);
                    if (frag == null) continue;

                    // Avoid “smearing” if a file defines multiple objects.
                    var defs = new DefinitionVisitor(currentDb);
                    frag.Accept(defs);
                    if (defs.Definitions.Count == 0) continue;

                    foreach (var def in defs.Definitions)
                    {
                        // Only enrich if defined object exists in catalog (keeps keys canonical).
                        if (!cat.Objects.ContainsKey(def.Key)) continue;

                        var v = new DataflowVisitor(cat, currentDb, def.Key);
                        def.Statement.Accept(v);
                    }
                }
            }
        }

        sealed class DefinitionVisitor : TSqlFragmentVisitor
        {
            readonly string _db;
            public List<(string Key, TSqlStatement Statement)> Definitions { get; } = new();

            public DefinitionVisitor(string db) => _db = db;

            public override void Visit(CreateProcedureStatement node) => Add(node.ProcedureReference?.Name, node);
            public override void Visit(CreateViewStatement node) => Add(node.SchemaObjectName, node);
            public override void Visit(CreateFunctionStatement node) => Add(node.Name, node);
            public override void Visit(CreateTableStatement node) => Add(node.SchemaObjectName, node);

            void Add(SchemaObjectName? n, TSqlStatement stmt)
            {
                if (n == null) return;
                var schema = n.SchemaIdentifier?.Value ?? "dbo";
                var name = n.BaseIdentifier?.Value ?? "";
                if (name.Length == 0) return;

                var key = $"{_db}.{schema}.{name}";
                Definitions.Add((key, stmt));
            }
        }

        sealed class DataflowVisitor : TSqlFragmentVisitor
        {
            readonly Catalog _cat;
            readonly string _currentDb;
            readonly string _ownerObjectKey;
            readonly SqlObject _ownerObject;

            public DataflowVisitor(Catalog cat, string currentDb, string ownerObjectKey)
            {
                _cat = cat;
                _currentDb = currentDb;
                _ownerObjectKey = ownerObjectKey;
                _ownerObject = cat.Objects[ownerObjectKey];
            }

            public override void Visit(InsertStatement node)
            {
                HandleInsert(node);
                base.Visit(node);
            }

            public override void Visit(UpdateStatement node)
            {
                HandleUpdate(node);
                base.Visit(node);
            }

            public override void Visit(MergeStatement node)
            {
                HandleMerge(node);
                base.Visit(node);
            }

            // -------------------------
            // INSERT ... SELECT support
            // -------------------------
            void HandleInsert(InsertStatement node)
            {
                var spec = node.InsertSpecification;
                if (spec == null) return;

                // Build alias scope for resolving RHS expressions.
                var aliases = AliasScope.Build(node, _currentDb);

                // Resolve target table (only real tables modeled in DacFx; skip @table vars, derived targets, etc.)
                var target = ResolveTargetTable(spec.Target, aliases);
                if (target == null) return;

                // Only support INSERT ... SELECT (MVP safe mapping).
                if (spec.InsertSource is not SelectInsertSource selSrc) return;

                // Need explicit target columns to map positionally.
                if (spec.Columns == null || spec.Columns.Count == 0) return;

                // ScriptDom version differences:
                // - In your environment, SelectInsertSource.Select is a QueryExpression.
                // We unwrap parentheses and require QuerySpecification (skip UNION/EXCEPT for now).
                var qe = Unwrap(selSrc.Select);
                if (qe is not QuerySpecification qs) return;

                if (qs.SelectElements == null) return;

                var selectExprs = new List<ScalarExpression>();
                foreach (var se in qs.SelectElements)
                {
                    // Support scalar select expressions only (covers your patterns; constants and expressions are fine).
                    if (se is SelectScalarExpression sse && sse.Expression != null)
                        selectExprs.Add(sse.Expression);
                    else
                        return; // SELECT *, non-scalar projections, etc. -> skip for safety
                }

                if (selectExprs.Count != spec.Columns.Count) return;

                for (int i = 0; i < spec.Columns.Count; i++)
                {
                    var tgtIds = spec.Columns[i].MultiPartIdentifier?.Identifiers;
                    if (tgtIds == null || tgtIds.Count == 0) continue;

                    var tgtColName = tgtIds[^1].Value;

                    var targetColKey = SqlNameResolver.ColKey(target.Value.Db, target.Value.Schema, target.Value.Table, tgtColName);
                    if (!_cat.Columns.TryGetValue(targetColKey, out var targetCol)) continue;

                    // Include table + proc in the data graph "along the way".
                    AddIfObjectExists(targetCol.DataParents, TargetTableKey(target.Value));
                    AddIfObjectExists(targetCol.DataParents, _ownerObjectKey);

                    var srcCols = CollectSourceColumns(selectExprs[i], aliases);
                    foreach (var src in srcCols)
                        targetCol.DataParents.Add(src);

                    // Table/proc-level data parents: propagate upstream tables.
                    PropagateUpstreamTables(TargetTableKey(target.Value), srcCols);
                }
            }

            static QueryExpression? Unwrap(QueryExpression? qe)
            {
                while (qe is QueryParenthesisExpression qpe)
                    qe = qpe.QueryExpression;
                return qe;
            }

            // -------------------------
            // UPDATE ... SET ... FROM support
            // -------------------------
            void HandleUpdate(UpdateStatement node)
            {
                var spec = node.UpdateSpecification;
                if (spec == null) return;

                var aliases = AliasScope.Build(node, _currentDb);

                // IMPORTANT: update target may be an alias-only reference (like UPDATE [ods_account])
                var target = ResolveTargetTable(spec.Target, aliases);
                if (target == null) return;

                if (spec.SetClauses == null) return;

                foreach (var sc in spec.SetClauses)
                {
                    if (sc is not AssignmentSetClause asc) continue;

                    var lhsIds = asc.Column?.MultiPartIdentifier?.Identifiers;
                    if (lhsIds == null || lhsIds.Count == 0) continue;

                    // LHS might be t.Col or Col; we treat the column name as the last identifier.
                    var tgtColName = lhsIds[^1].Value;

                    var targetColKey = SqlNameResolver.ColKey(target.Value.Db, target.Value.Schema, target.Value.Table, tgtColName);
                    if (!_cat.Columns.TryGetValue(targetColKey, out var targetCol)) continue;

                    AddIfObjectExists(targetCol.DataParents, TargetTableKey(target.Value));
                    AddIfObjectExists(targetCol.DataParents, _ownerObjectKey);

                    if (asc.NewValue == null) continue;

                    var srcCols = CollectSourceColumns(asc.NewValue, aliases);
                    foreach (var src in srcCols)
                        targetCol.DataParents.Add(src);

                    PropagateUpstreamTables(TargetTableKey(target.Value), srcCols);
                }
            }

            // -------------------------
            // MERGE support (kept; MVP-safe)
            // -------------------------
            void HandleMerge(MergeStatement node)
            {
                var spec = node.MergeSpecification;
                if (spec == null) return;

                var aliases = AliasScope.Build(node, _currentDb);

                var target = ResolveTargetTable(spec.Target, aliases);
                if (target == null) return;

                if (spec.ActionClauses == null) return;

                foreach (var ac in spec.ActionClauses)
                {
                    if (ac.Action is UpdateMergeAction uma && uma.SetClauses != null)
                    {
                        foreach (var sc in uma.SetClauses)
                        {
                            if (sc is not AssignmentSetClause asc) continue;

                            var lhsIds = asc.Column?.MultiPartIdentifier?.Identifiers;
                            if (lhsIds == null || lhsIds.Count == 0) continue;

                            var tgtColName = lhsIds[^1].Value;

                            var targetColKey = SqlNameResolver.ColKey(target.Value.Db, target.Value.Schema, target.Value.Table, tgtColName);
                            if (!_cat.Columns.TryGetValue(targetColKey, out var targetCol)) continue;

                            AddIfObjectExists(targetCol.DataParents, TargetTableKey(target.Value));
                            AddIfObjectExists(targetCol.DataParents, _ownerObjectKey);

                            if (asc.NewValue == null) continue;

                            var srcCols = CollectSourceColumns(asc.NewValue, aliases);
                            foreach (var src in srcCols)
                                targetCol.DataParents.Add(src);

                            PropagateUpstreamTables(TargetTableKey(target.Value), srcCols);
                        }
                    }
                    else if (ac.Action is InsertMergeAction ima)
                    {
                        if (ima.Columns == null || ima.Source == null) continue;

                        // MVP: support VALUES row only
                        if (ima.Source is not ValuesInsertSource vis) continue;
                        if (vis.RowValues == null || vis.RowValues.Count == 0) continue;
                        if (vis.RowValues[0].ColumnValues == null) continue;

                        var values = vis.RowValues[0].ColumnValues;
                        if (values.Count != ima.Columns.Count) continue;

                        for (int i = 0; i < ima.Columns.Count; i++)
                        {
                            var colIds = ima.Columns[i].MultiPartIdentifier?.Identifiers;
                            if (colIds == null || colIds.Count == 0) continue;

                            var tgtColName = colIds[^1].Value;

                            var targetColKey = SqlNameResolver.ColKey(target.Value.Db, target.Value.Schema, target.Value.Table, tgtColName);
                            if (!_cat.Columns.TryGetValue(targetColKey, out var targetCol)) continue;

                            AddIfObjectExists(targetCol.DataParents, TargetTableKey(target.Value));
                            AddIfObjectExists(targetCol.DataParents, _ownerObjectKey);

                            var expr = values[i];
                            var srcCols = CollectSourceColumns(expr, aliases);
                            foreach (var src in srcCols)
                                targetCol.DataParents.Add(src);

                            PropagateUpstreamTables(TargetTableKey(target.Value), srcCols);
                        }
                    }
                }
            }

            static string TargetTableKey((string Db, string Schema, string Table) t) => SqlNameResolver.ObjKey(t.Db, t.Schema, t.Table);

            void PropagateUpstreamTables(string targetTableKey, HashSet<string> srcCols)
            {
                // Add loader proc as a data parent of the target table.
                if (_cat.Objects.TryGetValue(targetTableKey, out var targetTableObj))
                    targetTableObj.DataParents.Add(_ownerObjectKey);

                // Collect upstream table objects from source columns.
                foreach (var c in srcCols)
                {
                    var tableKey = ColumnKeyToTableKey(c);
                    if (tableKey == null) continue;

                    // Add upstream table to the target table's data parents.
                    if (_cat.Objects.TryGetValue(targetTableKey, out var tgtObj) && _cat.Objects.ContainsKey(tableKey))
                        tgtObj.DataParents.Add(tableKey);

                    // Also add upstream tables as proc data parents (so proc nodes appear in data graph traversals).
                    if (_cat.Objects.ContainsKey(tableKey))
                        _ownerObject.DataParents.Add(tableKey);
                }
            }

            static string? ColumnKeyToTableKey(string colKey)
            {
                // DB.Schema.Table.Column -> DB.Schema.Table
                var lastDot = colKey.LastIndexOf('.');
                if (lastDot <= 0) return null;
                return colKey.Substring(0, lastDot);
            }

            void AddIfObjectExists(HashSet<string> set, string key)
            {
                if (_cat.Objects.ContainsKey(key)) set.Add(key);
            }

            // ---------------------------------------
            // Shared helpers
            // ---------------------------------------
            (string Db, string Schema, string Table)? ResolveTargetTable(TableReference? tr, AliasScope aliases)
            {
                if (tr == null) return null;

                // Most common: NamedTableReference with schema object name.
                if (tr is NamedTableReference ntr)
                {
                    // 1) schema-qualified target (INSERT INTO [db].[sch].[tbl])
                    var direct = SqlNameResolver.TryResolveTableName(ntr.SchemaObject, _currentDb);
                    if (direct != null) return direct;

                    // 2) alias-only target (UPDATE [ods_account] ...)
                    var alias = ntr.Alias?.Value;
                    if (!string.IsNullOrWhiteSpace(alias) && aliases.TryResolve(alias, out var tByAlias))
                        return tByAlias;

                    // 3) sometimes ScriptDom stores alias-only target as base identifier; try resolve by its textual base name
                    // (this helps when Alias isn't set but the "name" matches an alias/table key in scope).
                    var baseName = ntr.SchemaObject?.BaseIdentifier?.Value;
                    if (!string.IsNullOrWhiteSpace(baseName) && aliases.TryResolve(baseName, out var tByName))
                        return tByName;

                    return null;
                }

                // Table variables / derived targets aren't in DacFx catalog: skip for safe lineage.
                return null;
            }

            HashSet<string> CollectSourceColumns(ScalarExpression expr, AliasScope aliases)
            {
                var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                expr.Accept(new ExprColumnCollector(_cat, aliases, _currentDb, set));
                return set;
            }

            sealed class ExprColumnCollector : TSqlFragmentVisitor
            {
                readonly Catalog _cat;
                readonly AliasScope _aliases;
                readonly string _currentDb;
                readonly HashSet<string> _out;

                public ExprColumnCollector(Catalog cat, AliasScope aliases, string currentDb, HashSet<string> output)
                {
                    _cat = cat;
                    _aliases = aliases;
                    _currentDb = currentDb;
                    _out = output;
                }

                public override void Visit(ColumnReferenceExpression node)
                {
                    if (SqlNameResolver.TryResolveColumnKey(node, _cat, _aliases, _currentDb, out var k))
                        _out.Add(k);

                    base.Visit(node);
                }
            }
        }
    }
}
