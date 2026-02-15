using System;
using System.Collections.Generic;
using System.IO;

namespace DocuGen
{
    internal enum SqlObjectType { Table, View, Proc, Function }

    internal sealed class Catalog
    {
        public HashSet<string> Databases { get; } = new(StringComparer.OrdinalIgnoreCase);
        public HashSet<(string Db, string Schema)> Schemas { get; } = new();
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
}
