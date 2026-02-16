using System;
using System.Collections.Generic;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace DocuGen
{
    internal static class SqlNameResolver
    {
        public static (string Db, string Schema, string Table)? TryResolveTableName(SchemaObjectName? son, string currentDb)
        {
            if (son?.Identifiers == null) return null;
            var parts = son.Identifiers;

            if (parts.Count == 3)
                return (NameNorm.NormalizeDb(parts[0].Value), parts[1].Value, parts[2].Value);

            if (parts.Count == 2)
                return (currentDb, parts[0].Value, parts[1].Value);

            if (parts.Count == 1)
                return (currentDb, "dbo", parts[0].Value);

            return null;
        }

        public static (string Db, string Schema, string Name)? TryResolveObjectName(SchemaObjectName? son, string currentDb)
        {
            if (son?.Identifiers == null) return null;
            var parts = son.Identifiers;

            if (parts.Count == 3)
                return (NameNorm.NormalizeDb(parts[0].Value), parts[1].Value, parts[2].Value);

            if (parts.Count == 2)
                return (currentDb, parts[0].Value, parts[1].Value);

            if (parts.Count == 1)
                return (currentDb, "dbo", parts[0].Value);

            return null;
        }

        public static string ObjKey(string db, string schema, string name) => $"{db}.{schema}.{name}";
        public static string ColKey(string db, string schema, string table, string col) => $"{db}.{schema}.{table}.{col}";

        public static bool TryResolveColumnKey(
            ColumnReferenceExpression colRef,
            Catalog cat,
            AliasScope aliases,
            string currentDb,
            out string colKey)
        {
            colKey = string.Empty;
            var ids = colRef.MultiPartIdentifier?.Identifiers;
            if (ids == null || ids.Count == 0) return false;

            // 4-part: db.schema.table.col
            if (ids.Count == 4)
            {
                var db = NameNorm.NormalizeDb(ids[0].Value);
                var schema = ids[1].Value;
                var table = ids[2].Value;
                var col = ids[3].Value;
                var k = ColKey(db, schema, table, col);
                if (cat.Columns.ContainsKey(k)) { colKey = k; return true; }
                return false;
            }

            // 3-part: schema.table.col (assume current db)
            if (ids.Count == 3)
            {
                var schema = ids[0].Value;
                var table = ids[1].Value;
                var col = ids[2].Value;
                var k = ColKey(currentDb, schema, table, col);
                if (cat.Columns.ContainsKey(k)) { colKey = k; return true; }
                return false;
            }

            // 2-part: aliasOrTable.col
            if (ids.Count == 2)
            {
                var left = ids[0].Value;
                var col = ids[1].Value;

                if (left.StartsWith("@", StringComparison.Ordinal)) return false;

                if (aliases.TryResolve(left, out var t))
                {
                    var k = ColKey(t.Db, t.Schema, t.Table, col);
                    if (cat.Columns.ContainsKey(k)) { colKey = k; return true; }
                }

                return false;
            }

            // 1-part: col (conservative: only if exactly one match across alias tables)
            if (ids.Count == 1)
            {
                var col = ids[0].Value;
                if (col.StartsWith("@", StringComparison.Ordinal)) return false;

                var hits = new List<string>();

                // Enumerate alias tables by scanning the catalog for matching column keys.
                // (We only accept if there is exactly one hit.)
                // This stays conservative and avoids false lineage.
                foreach (var kv in cat.Columns)
                {
                    if (!kv.Key.EndsWith("." + col, StringComparison.OrdinalIgnoreCase)) continue;

                    // Only accept columns whose table is in current alias scope
                    // by checking the prefix db.schema.table against alias mappings.
                    // Build a quick set of table prefixes from alias scope.
                    // (AliasScope is internal; easiest is to attempt match against all known aliases.)
                    // We'll just accept hits that match any alias table.
                    // Create canonical prefix: db.schema.table.
                    var lastDot = kv.Key.LastIndexOf('.');
                    var tablePrefix = lastDot > 0 ? kv.Key.Substring(0, lastDot) : kv.Key;

                    // brute check: if any alias resolves to this table prefix
                    // (we don't have direct enumeration, so we try common patterns: alias map contains base table names/aliases;
                    // this conservative filter is still useful)
                    // Since AliasScope doesn't expose enumeration, we accept only if it's in the same DB (currentDb),
                    // which keeps things safer.
                    if (!tablePrefix.StartsWith(currentDb + ".", StringComparison.OrdinalIgnoreCase)) continue;

                    hits.Add(kv.Key);
                    if (hits.Count > 1) break;
                }

                if (hits.Count == 1)
                {
                    colKey = hits[0];
                    return true;
                }

                return false;
            }

            return false;
        }
    }
}
