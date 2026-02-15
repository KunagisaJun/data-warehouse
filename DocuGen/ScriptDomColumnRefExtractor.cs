using System;
using System.Collections.Generic;
using System.IO;
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
                    var frag = Parse(file);
                    if (frag == null) continue;

                    var defs = new DefinitionVisitor(currentDb);
                    frag.Accept(defs);
                    if (defs.DefinedKeys.Count == 0) continue;

                    var edges = new EdgeVisitor(cat, currentDb);
                    frag.Accept(edges);

                    foreach (var defKey in defs.DefinedKeys)
                    {
                        if (!cat.Objects.TryGetValue(defKey, out var obj)) continue;
                        if (obj.Type == SqlObjectType.Table) continue;

                        obj.ReadsObjects.UnionWith(edges.ReadObjects);
                        obj.WritesObjects.UnionWith(edges.WriteObjects);
                        obj.CallsObjects.UnionWith(edges.CallObjects);

                        obj.ReadsColumns.UnionWith(edges.ReadColumns);
                        obj.WritesColumns.UnionWith(edges.WriteColumns);
                    }
                }
            }
        }

        static TSqlFragment? Parse(string path)
        {
            var parser = new TSql150Parser(true);
            var frag = parser.Parse(new StringReader(File.ReadAllText(path)), out var errors);
            return errors.Count == 0 ? frag : null;
        }

        sealed class DefinitionVisitor : TSqlFragmentVisitor
        {
            readonly string _db;
            public HashSet<string> DefinedKeys { get; } = new(StringComparer.OrdinalIgnoreCase);

            public DefinitionVisitor(string db) => _db = db;

            public override void Visit(CreateProcedureStatement node) => Add(node.ProcedureReference?.Name);
            public override void Visit(CreateViewStatement node) => Add(node.SchemaObjectName);
            public override void Visit(CreateFunctionStatement node) => Add(node.Name);
            public override void Visit(CreateTableStatement node) => Add(node.SchemaObjectName);

            void Add(SchemaObjectName? n)
            {
                if (n == null) return;
                var schema = n.SchemaIdentifier?.Value ?? "dbo";
                var name = n.BaseIdentifier?.Value ?? "";
                if (name.Length == 0) return;
                DefinedKeys.Add($"{_db}.{schema}.{name}");
            }
        }

        sealed class EdgeVisitor : TSqlFragmentVisitor
        {
            readonly Catalog _cat;
            readonly string _currentDb;

            readonly Stack<Dictionary<string, (string Db, string Schema, string Table)>> _aliasScopes = new();

            (string Db, string Schema, string Table)? _writeTarget;
            bool _inWriteColumns;

            public HashSet<string> ReadObjects { get; } = new(StringComparer.OrdinalIgnoreCase);
            public HashSet<string> WriteObjects { get; } = new(StringComparer.OrdinalIgnoreCase);
            public HashSet<string> CallObjects { get; } = new(StringComparer.OrdinalIgnoreCase);

            public HashSet<string> ReadColumns { get; } = new(StringComparer.OrdinalIgnoreCase);
            public HashSet<string> WriteColumns { get; } = new(StringComparer.OrdinalIgnoreCase);

            public EdgeVisitor(Catalog cat, string currentDb)
            {
                _cat = cat;
                _currentDb = currentDb;
            }

            public override void Visit(SelectStatement node)
            {
                PushAliases(node);
                base.Visit(node);
                _aliasScopes.Pop();
            }

            public override void Visit(InsertStatement node)
            {
                PushAliases(node);
                HandleInsert(node);
                base.Visit(node);
                _writeTarget = null;
                _aliasScopes.Pop();
            }

            public override void Visit(UpdateStatement node)
            {
                PushAliases(node);
                HandleUpdate(node);
                base.Visit(node);
                _writeTarget = null;
                _aliasScopes.Pop();
            }

            public override void Visit(DeleteStatement node)
            {
                PushAliases(node);
                HandleDelete(node);
                base.Visit(node);
                _aliasScopes.Pop();
            }

            public override void Visit(MergeStatement node)
            {
                PushAliases(node);
                HandleMerge(node);
                base.Visit(node);
                _writeTarget = null;
                _aliasScopes.Pop();
            }

            public override void Visit(TruncateTableStatement node)
            {
                var t = ParseTableName(node.TableName);
                if (t != null) AddObj(WriteObjects, t.Value.Db, t.Value.Schema, t.Value.Table);
                base.Visit(node);
            }

            public override void Visit(ExecuteStatement node)
            {
                var exec = node.ExecuteSpecification?.ExecutableEntity as ExecutableProcedureReference;
                var name = exec?.ProcedureReference?.ProcedureReference?.Name;
                if (name != null)
                {
                    var k = ParseObjectName(name);
                    if (k != null) AddObj(CallObjects, k.Value.Db, k.Value.Schema, k.Value.Name);
                }
                base.Visit(node);
            }

            public override void Visit(NamedTableReference node)
            {
                // tables in FROM/JOIN are reads
                var t = ParseTableName(node.SchemaObject);
                if (t != null) AddObj(ReadObjects, t.Value.Db, t.Value.Schema, t.Value.Table);
                base.Visit(node);
            }

            public override void Visit(SetClause node)
            {
                // LHS column refs inside SET are writes
                _inWriteColumns = true;
                base.Visit(node);
                _inWriteColumns = false;
            }

            public override void Visit(ColumnReferenceExpression node)
            {
                var ids = node.MultiPartIdentifier?.Identifiers;
                if (ids == null || ids.Count == 0) { base.Visit(node); return; }

                // writes: INSERT column list or UPDATE SET lhs
                if (_writeTarget != null && _inWriteColumns)
                {
                    // INSERT list gives 1-part; UPDATE lhs is often 2-part alias.col
                    var col = ids.Count == 1 ? ids[0].Value : ids[^1].Value;
                    AddCol(WriteColumns, _writeTarget.Value.Db, _writeTarget.Value.Schema, _writeTarget.Value.Table, col);
                    base.Visit(node);
                    return;
                }

                // reads
                if (ids.Count == 4)
                {
                    AddCol(ReadColumns,
                        NameNorm.NormalizeDb(ids[0].Value),
                        ids[1].Value,
                        ids[2].Value,
                        ids[3].Value);
                    base.Visit(node);
                    return;
                }

                if (ids.Count == 3)
                {
                    AddCol(ReadColumns, _currentDb, ids[0].Value, ids[1].Value, ids[2].Value);
                    base.Visit(node);
                    return;
                }

                if (ids.Count == 2)
                {
                    var t = ids[0].Value;
                    var col = ids[1].Value;

                    if (t.StartsWith("@", StringComparison.Ordinal)) { base.Visit(node); return; }

                    if (TryResolveAlias(t, out var resolved))
                    {
                        AddCol(ReadColumns, resolved.Db, resolved.Schema, resolved.Table, col);
                        base.Visit(node);
                        return;
                    }

                    base.Visit(node);
                    return;
                }

                base.Visit(node);
            }

            void HandleInsert(InsertStatement node)
            {
                var spec = node.InsertSpecification;
                var tgt = ParseTableRef(spec?.Target);
                if (tgt == null) return;

                AddObj(WriteObjects, tgt.Value.Db, tgt.Value.Schema, tgt.Value.Table);
                _writeTarget = tgt;

                var cols = spec?.Columns;
                if (cols != null && cols.Count > 0)
                {
                    _inWriteColumns = true;
                    foreach (var c in cols) Visit(c);
                    _inWriteColumns = false;
                }
            }

            void HandleUpdate(UpdateStatement node)
            {
                var spec = node.UpdateSpecification;
                var tgt = ParseTableRef(spec?.Target);
                if (tgt == null) return;

                AddObj(WriteObjects, tgt.Value.Db, tgt.Value.Schema, tgt.Value.Table);
                _writeTarget = tgt;
            }

            void HandleDelete(DeleteStatement node)
            {
                var spec = node.DeleteSpecification;
                var tgt = ParseTableRef(spec?.Target);
                if (tgt == null) return;

                AddObj(WriteObjects, tgt.Value.Db, tgt.Value.Schema, tgt.Value.Table);
            }

            void HandleMerge(MergeStatement node)
            {
                var tgt = ParseTableRef(node.MergeSpecification?.Target);
                if (tgt == null) return;

                AddObj(WriteObjects, tgt.Value.Db, tgt.Value.Schema, tgt.Value.Table);
                _writeTarget = tgt;
            }

            void PushAliases(TSqlFragment scopeNode)
            {
                var map = new Dictionary<string, (string Db, string Schema, string Table)>(StringComparer.OrdinalIgnoreCase);
                scopeNode.Accept(new AliasCollector(_currentDb, map));
                _aliasScopes.Push(map);
            }

            bool TryResolveAlias(string name, out (string Db, string Schema, string Table) t)
            {
                foreach (var scope in _aliasScopes)
                {
                    if (scope.TryGetValue(name, out t)) return true;
                }
                t = default;
                return false;
            }

            void AddObj(HashSet<string> set, string db, string schema, string name)
            {
                var key = $"{db}.{schema}.{name}";
                if (_cat.Objects.ContainsKey(key)) set.Add(key);
            }

            void AddCol(HashSet<string> set, string db, string schema, string table, string col)
            {
                var key = $"{db}.{schema}.{table}.{col}";
                if (_cat.Columns.ContainsKey(key)) set.Add(key);
            }

            (string Db, string Schema, string Table)? ParseTableRef(TableReference? tr)
            {
                if (tr is NamedTableReference n) return ParseTableName(n.SchemaObject);
                return null;
            }

            (string Db, string Schema, string Table)? ParseTableName(SchemaObjectName? son)
            {
                if (son?.Identifiers == null) return null;
                var parts = son.Identifiers;

                if (parts.Count == 3)
                    return (NameNorm.NormalizeDb(parts[0].Value), parts[1].Value, parts[2].Value);

                if (parts.Count == 2)
                    return (_currentDb, parts[0].Value, parts[1].Value);

                return null;
            }

            (string Db, string Schema, string Name)? ParseObjectName(SchemaObjectName son)
            {
                var parts = son.Identifiers;
                if (parts == null) return null;

                if (parts.Count == 3)
                    return (NameNorm.NormalizeDb(parts[0].Value), parts[1].Value, parts[2].Value);

                if (parts.Count == 2)
                    return (_currentDb, parts[0].Value, parts[1].Value);

                return null;
            }
        }

        sealed class AliasCollector : TSqlFragmentVisitor
        {
            readonly string _currentDb;
            readonly Dictionary<string, (string Db, string Schema, string Table)> _map;

            public AliasCollector(string currentDb, Dictionary<string, (string Db, string Schema, string Table)> map)
            {
                _currentDb = currentDb;
                _map = map;
            }

            public override void Visit(NamedTableReference node)
            {
                var alias = node.Alias?.Value;
                var son = node.SchemaObject;

                if (string.IsNullOrWhiteSpace(alias) || son?.Identifiers == null)
                {
                    base.Visit(node);
                    return;
                }

                if (alias.StartsWith("@", StringComparison.Ordinal))
                {
                    base.Visit(node);
                    return;
                }

                var parts = son.Identifiers;

                if (parts.Count == 3)
                    _map[alias] = (NameNorm.NormalizeDb(parts[0].Value), parts[1].Value, parts[2].Value);
                else if (parts.Count == 2)
                    _map[alias] = (_currentDb, parts[0].Value, parts[1].Value);

                base.Visit(node);
            }
        }
    }
}
