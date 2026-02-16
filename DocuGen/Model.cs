using System;
using System.Collections.Generic;
using System.IO;

namespace DocuGen
{
    internal enum SqlObjectType { Table, View, Proc, Function }

    internal sealed class Catalog
    {
        public HashSet<string> Databases { get; } = new(StringComparer.OrdinalIgnoreCase);

        // Use case-insensitive equality for Db/Schema tuples to avoid duplicate notes differing only by casing.
        public HashSet<(string Db, string Schema)> Schemas { get; } = new(DbSchemaComparer.OrdinalIgnoreCase);

        public Dictionary<string, SqlObject> Objects { get; } = new(StringComparer.OrdinalIgnoreCase);   // db.schema.obj
        public Dictionary<string, SqlColumn> Columns { get; } = new(StringComparer.OrdinalIgnoreCase); // db.schema.table.col
    }

    internal sealed class SqlObject
    {
        public required string Db { get; init; }
        public required string Schema { get; init; }
        public required string Name { get; init; }
        public required SqlObjectType Type { get; init; }
        public required string Key { get; init; }

        // Canonical defining statement for this object, if discovered (e.g., CREATE VIEW/PROC/FUNCTION/TABLE ...).
        // This is embedded into the generated markdown note body.
        public string? DefinitionSql { get; set; }

        public HashSet<string> ReadsObjects { get; } = new(StringComparer.OrdinalIgnoreCase);
        public HashSet<string> WritesObjects { get; } = new(StringComparer.OrdinalIgnoreCase);
        public HashSet<string> CallsObjects { get; } = new(StringComparer.OrdinalIgnoreCase);

        public HashSet<string> ReadsColumns { get; } = new(StringComparer.OrdinalIgnoreCase);
        public HashSet<string> WritesColumns { get; } = new(StringComparer.OrdinalIgnoreCase);
    }

    internal sealed class SqlColumn
    {
        public required string Db { get; init; }
        public required string Schema { get; init; }
        public required string Table { get; init; }
        public required string Name { get; init; }
        public required string Key { get; init; }
    }

    internal static class NameNorm
    {
        public static string NormalizeDb(string db)
        {
            if (db.Length >= 4 && db.StartsWith("$(", StringComparison.Ordinal) && db.EndsWith(")", StringComparison.Ordinal))
                return db.Substring(2, db.Length - 3);
            return db;
        }

        public static string SafeFile(string name)
        {
            foreach (var ch in Path.GetInvalidFileNameChars())
                name = name.Replace(ch, '_');
            return name;
        }
    }

    internal sealed class DbSchemaComparer : IEqualityComparer<(string Db, string Schema)>
    {
        public static readonly DbSchemaComparer OrdinalIgnoreCase = new(StringComparer.OrdinalIgnoreCase);

        readonly StringComparer _cmp;
        DbSchemaComparer(StringComparer cmp) => _cmp = cmp;

        public bool Equals((string Db, string Schema) x, (string Db, string Schema) y) =>
            _cmp.Equals(x.Db, y.Db) && _cmp.Equals(x.Schema, y.Schema);

        public int GetHashCode((string Db, string Schema) obj) =>
            HashCode.Combine(_cmp.GetHashCode(obj.Db ?? string.Empty), _cmp.GetHashCode(obj.Schema ?? string.Empty));
    }
}
