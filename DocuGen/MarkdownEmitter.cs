using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Collections.Generic;

namespace DocuGen
{
    internal static class MarkdownEmitter
    {
        const string ParentSectionTitle = "## zc-plugin-parent-node";

        public static void Emit(string outRoot, Catalog cat)
        {
            var dbDir = Path.Combine(outRoot, "database");
            var schemaDir = Path.Combine(outRoot, "schema");
            var objDir = Path.Combine(outRoot, "object");
            var colDir = Path.Combine(outRoot, "column");

            Directory.CreateDirectory(dbDir);
            Directory.CreateDirectory(schemaDir);
            Directory.CreateDirectory(objDir);
            Directory.CreateDirectory(colDir);

            foreach (var db in cat.Databases.OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
                Write(Path.Combine(dbDir, $"{NameNorm.SafeFile(db)}.md"), RenderDb(db, cat));

            foreach (var s in cat.Schemas.OrderBy(x => x.Db, StringComparer.OrdinalIgnoreCase)
                                         .ThenBy(x => x.Schema, StringComparer.OrdinalIgnoreCase))
                Write(Path.Combine(schemaDir, $"{NameNorm.SafeFile($"{s.Db}.{s.Schema}")}.md"),
                    RenderSchema(s.Db, s.Schema, cat));

            foreach (var c in cat.Columns.Values.OrderBy(x => x.Key, StringComparer.OrdinalIgnoreCase))
                Write(Path.Combine(colDir, $"{NameNorm.SafeFile(c.Key)}.md"), RenderColumn(c));

            foreach (var o in cat.Objects.Values.OrderBy(x => x.Type)
                                               .ThenBy(x => x.Key, StringComparer.OrdinalIgnoreCase))
            {
                var folder = Path.Combine(objDir, o.Type.ToString().ToLowerInvariant());
                Directory.CreateDirectory(folder);
                Write(Path.Combine(folder, $"{NameNorm.SafeFile(o.Key)}.md"), RenderObject(o, cat));
            }
        }

        static string Yaml(string key, string type, string db)
        {
            var tags = new[] { "sql", $"db/{db}", $"type/{type}" };

            var sb = new StringBuilder();
            sb.AppendLine("---");
            sb.AppendLine($"tags: [{string.Join(", ", tags.Select(EscapeYamlTag))}]");
            sb.AppendLine($"docugen_key: \"{key}\"");
            sb.AppendLine($"docugen_type: \"{type}\"");
            sb.AppendLine($"docugen_db: \"{db}\"");
            sb.AppendLine("---");
            sb.AppendLine();
            return sb.ToString();
        }

        static string EscapeYamlTag(string t)
        {
            // YAML inline list: safest to quote if special chars exist.
            if (t.Any(ch => char.IsWhiteSpace(ch) || ch == ':' || ch == '[' || ch == ']' || ch == ',' || ch == '"' || ch == '\''))
                return $"\"{t.Replace("\"", "\\\"")}\"";
            return t;
        }

        static string RenderDb(string db, Catalog cat)
        {
            var sb = new StringBuilder();
            sb.Append(Yaml(db, "database", db));
            sb.AppendLine($"# {db}");
            sb.AppendLine();
            sb.AppendLine("## Schemas");

            foreach (var s in cat.Schemas.Where(x => db.Equals(x.Db, StringComparison.OrdinalIgnoreCase))
                                         .Select(x => x.Schema)
                                         .Distinct(StringComparer.OrdinalIgnoreCase)
                                         .OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
                sb.AppendLine($"- [[{db}.{s}]]");

            sb.AppendLine();
            sb.AppendLine(ParentSectionTitle);
            sb.AppendLine("- _(none)_");
            sb.AppendLine();

            return sb.ToString();
        }

        static string RenderSchema(string db, string schema, Catalog cat)
        {
            var key = $"{db}.{schema}";
            var sb = new StringBuilder();
            sb.Append(Yaml(key, "schema", db));
            sb.AppendLine($"# {db}.{schema}");
            sb.AppendLine();
            sb.AppendLine($"- [[{db}]]");
            sb.AppendLine();
            sb.AppendLine("## Objects");

            foreach (var o in cat.Objects.Values.Where(o =>
                         db.Equals(o.Db, StringComparison.OrdinalIgnoreCase) &&
                         schema.Equals(o.Schema, StringComparison.OrdinalIgnoreCase))
                     .OrderBy(o => o.Type)
                     .ThenBy(o => o.Name, StringComparer.OrdinalIgnoreCase))
                sb.AppendLine($"- [[{o.Key}]]");

            sb.AppendLine();
            sb.AppendLine(ParentSectionTitle);
            sb.AppendLine("- _(none)_");
            sb.AppendLine();

            return sb.ToString();
        }

        static string RenderObject(SqlObject o, Catalog cat)
        {
            var typeTag = o.Type.ToString().ToLowerInvariant();
            var sb = new StringBuilder();
            sb.Append(Yaml(o.Key, typeTag, o.Db));
            sb.AppendLine($"# {o.Key}");
            sb.AppendLine();
            sb.AppendLine($"- Schema: [[{o.Db}.{o.Schema}]]");
            sb.AppendLine($"- Type: `{o.Type}`");
            sb.AppendLine();

            if (o.Type == SqlObjectType.Table)
            {
                sb.AppendLine("## Columns");
                foreach (var c in cat.Columns.Values.Where(c =>
                             o.Db.Equals(c.Db, StringComparison.OrdinalIgnoreCase) &&
                             o.Schema.Equals(c.Schema, StringComparison.OrdinalIgnoreCase) &&
                             o.Name.Equals(c.Table, StringComparison.OrdinalIgnoreCase))
                         .OrderBy(c => c.Name, StringComparer.OrdinalIgnoreCase))
                    sb.AppendLine($"- [[{c.Key}]]");

                sb.AppendLine();
                sb.AppendLine(ParentSectionTitle);
                sb.AppendLine("- _(none)_");
                sb.AppendLine();

                return sb.ToString();
            }

            // Parent lineage = everything this object references directly.
            var parents = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            parents.UnionWith(o.ReadsObjects);
            parents.UnionWith(o.WritesObjects);
            parents.UnionWith(o.CallsObjects);
            parents.UnionWith(o.ReadsColumns);
            parents.UnionWith(o.WritesColumns);

            sb.AppendLine(ParentSectionTitle);
            if (parents.Count == 0)
            {
                sb.AppendLine("- _(none detected)_");
            }
            else
            {
                foreach (var k in parents.OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
                    sb.AppendLine($"- [[{k}]]");
            }
            sb.AppendLine();

            return sb.ToString();
        }

        static string RenderColumn(SqlColumn c)
        {
            var sb = new StringBuilder();
            sb.Append(Yaml(c.Key, "column", c.Db));
            sb.AppendLine($"# {c.Key}");
            sb.AppendLine();
            sb.AppendLine($"- Table: [[{c.Db}.{c.Schema}.{c.Table}]]");
            sb.AppendLine();

            // Critical: make column -> table a "parent" edge so closure includes columns.
            sb.AppendLine(ParentSectionTitle);
            sb.AppendLine($"- [[{c.Db}.{c.Schema}.{c.Table}]]");
            sb.AppendLine();

            sb.AppendLine("> Use backlinks to see which procs/views/functions reference this column.");
            return sb.ToString();
        }

        static void Write(string path, string content) => File.WriteAllText(path, content, Encoding.UTF8);
    }
}
