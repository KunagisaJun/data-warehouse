using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace DocuGen
{
    internal static class ScriptDomColumnRefExtractor
    {
        public static void Enrich(Catalog cat, Dictionary<string, List<string>> sqlFilesByDb)
        {
            // Build a per-DB lookup for resolving Table.Column uniquely across schemas
            var byDbTableCol = BuildTableColumnIndex(cat);

            foreach (var (dbRaw, files) in sqlFilesByDb)
            {
                var currentDb = NameNorm.NormalizeDb(dbRaw);

                foreach (var file in files)
                {
                    var frag = Parse(file);
                    if (frag == null) continue;

                    var def = new DefinitionVisitor(currentDb);
                    frag.Accept(def);
                    if (def.DefinedObjectKeys.Count == 0) continue;

                    var refs = new ColumnRefVisitor(cat, byDbTableCol, currentDb);
                    frag.Accept(refs);

                    foreach (var objKey in def.DefinedObjectKeys)
                    {
                        if (!cat.Objects.TryGetValue(objKey, out var obj)) continue;
                        if (obj.Type == SqlObjectType.Table) continue;
                        obj.ReferencedColumns.UnionWith(refs.ReferencedColumns);
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

        static Dictionary<(string Db, string Table, string Col), List<string>> BuildTableColumnIndex(Catalog cat)
        {
            var dict = new Dictionary<(string Db, string Table, string Col), List<string>>();

            foreach (var c in cat.Columns.Values)
            {
                var k = (c.Db, c.Table, c.Name);
                if (!dict.TryGetValue(k, out var list))
                    dict[k] = list = new List<string>();
                list.Add(c.Key); // full key db.schema.table.col
            }
            return dict;
        }

        sealed class DefinitionVisitor : TSqlFragmentVisitor
        {
            readonly string _db;
            public HashSet<string> DefinedObjectKeys { get; } = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            public DefinitionVisitor(string db) => _db = db;

            public override void Visit(CreateProcedureStatement node) => Add(GetProcName(node));
            public override void Visit(CreateViewStatement node) => Add(node.SchemaObjectName);
            public override void Visit(CreateFunctionStatement node) => Add(node.Name);
            public override void Visit(CreateTableStatement node) => Add(node.SchemaObjectName);

            void Add(SchemaObjectName? son)
            {
                if (son == null) return;
                var schema = son.SchemaIdentifier?.Value ?? "dbo";
                var name = son.BaseIdentifier?.Value ?? "";
                if (name.Length == 0) return;
                DefinedObjectKeys.Add($"{_db}.{schema}.{name}");
            }

            static SchemaObjectName? GetProcName(CreateProcedureStatement node)
                => node.ProcedureReference?.Name; // if this fails in your ScriptDom version, paste error and I’ll swap to reflection getter.
        }

        sealed class ColumnRefVisitor : TSqlFragmentVisitor
        {
            readonly Catalog _cat;
            readonly Dictionary<(string Db, string Table, string Col), List<string>> _idx;
            readonly string _currentDb;

            public HashSet<string> ReferencedColumns { get; } = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            public ColumnRefVisitor(
                Catalog cat,
                Dictionary<(string Db, string Table, string Col), List<string>> idx,
                string currentDb)
            {
                _cat = cat;
                _idx = idx;
                _currentDb = currentDb;
            }

            public override void Visit(ColumnReferenceExpression node)
            {
                var ids = node.MultiPartIdentifier?.Identifiers;
                if (ids == null) { base.Visit(node); return; }

                // 1-part forbidden -> ignore
                if (ids.Count == 1) { base.Visit(node); return; }

                // 4-part: DB.Schema.Table.Col
                if (ids.Count == 4)
                {
                    var db = NameNorm.NormalizeDb(ids[0].Value);
                    var schema = ids[1].Value;
                    var table = ids[2].Value;
                    var col = ids[3].Value;

                    var key = $"{db}.{schema}.{table}.{col}";
                    if (_cat.Columns.ContainsKey(key))
                        ReferencedColumns.Add(key);

                    base.Visit(node);
                    return;
                }

                // 3-part: Schema.Table.Col (DB inferred)
                if (ids.Count == 3)
                {
                    var schema = ids[0].Value;
                    var table = ids[1].Value;
                    var col = ids[2].Value;

                    var key = $"{_currentDb}.{schema}.{table}.{col}";
                    if (_cat.Columns.ContainsKey(key))
                        ReferencedColumns.Add(key);

                    base.Visit(node);
                    return;
                }

                // 2-part: Table.Col (bind only if unique within current DB)
                if (ids.Count == 2)
                {
                    var table = ids[0].Value;
                    var col = ids[1].Value;

                    if (_idx.TryGetValue((_currentDb, table, col), out var matches) && matches.Count == 1)
                        ReferencedColumns.Add(matches[0]);

                    base.Visit(node);
                    return;
                }

                base.Visit(node);
            }
        }
    }
}
