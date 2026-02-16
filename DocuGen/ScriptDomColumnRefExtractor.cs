using System;
using System.Collections.Generic;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace DocuGen
{
    internal static class ScriptDomColumnRefExtractor
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

                    var defs = new DefinitionVisitor(currentDb);
                    frag.Accept(defs);
                    if (defs.Definitions.Count == 0) continue;

                    foreach (var def in defs.Definitions)
                    {
                        if (!cat.Objects.TryGetValue(def.Key, out var obj)) continue;

                        // Capture definition SQL once (optional – your emitter uses it)
                        if (string.IsNullOrWhiteSpace(obj.DefinitionSql) && !string.IsNullOrWhiteSpace(def.DefinitionSql))
                            obj.DefinitionSql = def.DefinitionSql;

                        // Tables: don’t collect “reads/writes” edges from their create statement.
                        if (obj.Type == SqlObjectType.Table) continue;

                        var v = new RefVisitor(cat, currentDb);
                        def.Statement.Accept(v);

                        obj.ReadsObjects.UnionWith(v.ReadObjects);
                        obj.WritesObjects.UnionWith(v.WriteObjects);
                        obj.CallsObjects.UnionWith(v.CallObjects);

                        obj.ReadsColumns.UnionWith(v.ReadColumns);
                        obj.WritesColumns.UnionWith(v.WriteColumns);
                    }
                }
            }
        }

        sealed class DefinitionVisitor : TSqlFragmentVisitor
        {
            readonly string _db;
            public List<(string Key, TSqlStatement Statement, string DefinitionSql)> Definitions { get; } = new();

            static readonly Sql150ScriptGenerator ScriptGen = new(new SqlScriptGeneratorOptions
            {
                KeywordCasing = KeywordCasing.Uppercase,
                IncludeSemicolons = true
            });

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

                string sql;
                try { ScriptGen.GenerateScript(stmt, out sql); }
                catch { sql = string.Empty; }

                Definitions.Add((key, stmt, sql ?? string.Empty));
            }
        }

        sealed class RefVisitor : TSqlFragmentVisitor
        {
            readonly Catalog _cat;
            readonly string _currentDb;

            public HashSet<string> ReadObjects { get; } = new(StringComparer.OrdinalIgnoreCase);
            public HashSet<string> WriteObjects { get; } = new(StringComparer.OrdinalIgnoreCase);
            public HashSet<string> CallObjects { get; } = new(StringComparer.OrdinalIgnoreCase);

            public HashSet<string> ReadColumns { get; } = new(StringComparer.OrdinalIgnoreCase);
            public HashSet<string> WriteColumns { get; } = new(StringComparer.OrdinalIgnoreCase);

            (string Db, string Schema, string Table)? _writeTarget;
            bool _inWriteColumns;

            public RefVisitor(Catalog cat, string currentDb)
            {
                _cat = cat;
                _currentDb = currentDb;
            }

            public override void Visit(InsertStatement node)
            {
                var aliases = AliasScope.Build(node, _currentDb);
                var spec = node.InsertSpecification;
                var target = ResolveTargetTable(spec?.Target);
                if (target != null)
                {
                    AddObj(WriteObjects, target.Value.Db, target.Value.Schema, target.Value.Table);
                    _writeTarget = target;
                }

                base.Visit(node);
                _writeTarget = null;
            }

            public override void Visit(UpdateStatement node)
            {
                var aliases = AliasScope.Build(node, _currentDb);
                var spec = node.UpdateSpecification;
                var target = ResolveTargetTable(spec?.Target);
                if (target != null)
                {
                    AddObj(WriteObjects, target.Value.Db, target.Value.Schema, target.Value.Table);
                    _writeTarget = target;
                }

                base.Visit(node);
                _writeTarget = null;
            }

            public override void Visit(DeleteStatement node)
            {
                var aliases = AliasScope.Build(node, _currentDb);
                var spec = node.DeleteSpecification;
                var target = ResolveTargetTable(spec?.Target);
                if (target != null)
                    AddObj(WriteObjects, target.Value.Db, target.Value.Schema, target.Value.Table);

                base.Visit(node);
            }

            public override void Visit(MergeStatement node)
            {
                var aliases = AliasScope.Build(node, _currentDb);
                var spec = node.MergeSpecification;
                var target = ResolveTargetTable(spec?.Target);
                if (target != null)
                {
                    AddObj(WriteObjects, target.Value.Db, target.Value.Schema, target.Value.Table);
                    _writeTarget = target;
                }

                base.Visit(node);
                _writeTarget = null;
            }

            public override void Visit(TruncateTableStatement node)
            {
                var t = SqlNameResolver.TryResolveTableName(node.TableName, _currentDb);
                if (t != null) AddObj(WriteObjects, t.Value.Db, t.Value.Schema, t.Value.Table);
                base.Visit(node);
            }

            public override void Visit(NamedTableReference node)
            {
                var t = SqlNameResolver.TryResolveTableName(node.SchemaObject, _currentDb);
                if (t != null) AddObj(ReadObjects, t.Value.Db, t.Value.Schema, t.Value.Table);
                base.Visit(node);
            }

            public override void Visit(ExecuteStatement node)
            {
                var exec = node.ExecuteSpecification?.ExecutableEntity as ExecutableProcedureReference;
                var name = exec?.ProcedureReference?.ProcedureReference?.Name;
                if (name != null)
                {
                    var o = SqlNameResolver.TryResolveObjectName(name, _currentDb);
                    if (o != null) AddObj(CallObjects, o.Value.Db, o.Value.Schema, o.Value.Name);
                }

                base.Visit(node);
            }

            public override void Visit(SetClause node)
            {
                _inWriteColumns = true;
                base.Visit(node);
                _inWriteColumns = false;
            }

            public override void Visit(ColumnReferenceExpression node)
            {
                // Determine alias scope for this expression by building it for the nearest statement.
                // For simplicity and to keep this extractor small, we conservatively rebuild scope at statement level
                // via a fallback: if it resolves using zero aliases, only 3/4-part keys will work.
                // If you want maximum 2-part alias coverage here, we can thread AliasScope through per-statement like dataflow does.
                var aliases = AliasScope.Build(node, _currentDb);

                // Write columns (SET clause)
                if (_writeTarget != null && _inWriteColumns)
                {
                    var ids = node.MultiPartIdentifier?.Identifiers;
                    if (ids != null && ids.Count > 0)
                    {
                        var col = ids.Count == 1 ? ids[0].Value : ids[^1].Value;
                        AddCol(WriteColumns, _writeTarget.Value.Db, _writeTarget.Value.Schema, _writeTarget.Value.Table, col);
                    }

                    base.Visit(node);
                    return;
                }

                if (SqlNameResolver.TryResolveColumnKey(node, _cat, aliases, _currentDb, out var k))
                    ReadColumns.Add(k);

                base.Visit(node);
            }

            (string Db, string Schema, string Table)? ResolveTargetTable(TableReference? tr)
            {
                if (tr == null) return null;

                if (tr is NamedTableReference ntr)
                    return SqlNameResolver.TryResolveTableName(ntr.SchemaObject, _currentDb);

                return null;
            }

            void AddObj(HashSet<string> set, string db, string schema, string name)
            {
                var key = SqlNameResolver.ObjKey(db, schema, name);
                if (_cat.Objects.ContainsKey(key)) set.Add(key);
            }

            void AddCol(HashSet<string> set, string db, string schema, string table, string col)
            {
                var key = SqlNameResolver.ColKey(db, schema, table, col);
                if (_cat.Columns.ContainsKey(key)) set.Add(key);
            }
        }
    }
}
