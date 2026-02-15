using System;
using System.IO;
using System.Linq;
using System.Text;

namespace DocuGen
{
    internal static class MarkdownEmitter
    {
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

        static string RenderDb(string db, Catalog cat)
        {
            var sb = new StringBuilder();
            sb.AppendLine($"# {db}");
            sb.AppendLine();
            sb.AppendLine("## Schemas");

            foreach (var s in cat.Schemas.Where(x => string.Equals(x.Db, db, StringComparison.OrdinalIgnoreCase))
                                         .Select(x => x.Schema)
                                         .Distinct(StringComparer.OrdinalIgnoreCase)
                                         .OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
            {
                sb.AppendLine($"- [[{db}.{s}]]");
            }

            return sb.ToString();
        }

        static string RenderSchema(string db, string schema, Catalog cat)
        {
            var sb = new StringBuilder();
            sb.AppendLine($"# {db}.{schema}");
            sb.AppendLine();
            sb.AppendLine($"- [[{db}]]");
            sb.AppendLine();
            sb.AppendLine("## Objects");

            foreach (var o in cat.Objects.Values.Where(o =>
                         string.Equals(o.Db, db, StringComparison.OrdinalIgnoreCase) &&
                         string.Equals(o.Schema, schema, StringComparison.OrdinalIgnoreCase))
                     .OrderBy(o => o.Type)
                     .ThenBy(o => o.Name, StringComparer.OrdinalIgnoreCase))
            {
                sb.AppendLine($"- [[{o.Key}]]");
            }

            return sb.ToString();
        }

        static string RenderObject(SqlObject o, Catalog cat)
        {
            var sb = new StringBuilder();
            sb.AppendLine($"# {o.Key}");
            sb.AppendLine();
            sb.AppendLine($"- Schema: [[{o.Db}.{o.Schema}]]");
            sb.AppendLine($"- Type: `{o.Type}`");
            sb.AppendLine();

            if (o.Type == SqlObjectType.Table)
            {
                sb.AppendLine("## Columns");
                foreach (var c in cat.Columns.Values.Where(c =>
                             string.Equals(c.Db, o.Db, StringComparison.OrdinalIgnoreCase) &&
                             string.Equals(c.Schema, o.Schema, StringComparison.OrdinalIgnoreCase) &&
                             string.Equals(c.Table, o.Name, StringComparison.OrdinalIgnoreCase))
                         .OrderBy(c => c.Name, StringComparer.OrdinalIgnoreCase))
                {
                    sb.AppendLine($"- [[{c.Key}]]");
                }
                return sb.ToString();
            }

            WriteSection(sb, "## Reads objects", o.ReadsObjects);
            WriteSection(sb, "## Writes objects", o.WritesObjects);
            WriteSection(sb, "## Calls objects", o.CallsObjects);

            WriteSection(sb, "## Reads columns", o.ReadsColumns);
            WriteSection(sb, "## Writes columns", o.WritesColumns);

            return sb.ToString();
        }

        static void WriteSection(StringBuilder sb, string title, System.Collections.Generic.HashSet<string> items)
        {
            sb.AppendLine(title);
            if (items.Count == 0) { sb.AppendLine("- _(none detected)_"); sb.AppendLine(); return; }
            foreach (var k in items.OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
                sb.AppendLine($"- [[{k}]]");
            sb.AppendLine();
        }

        static string RenderColumn(SqlColumn c)
        {
            var sb = new StringBuilder();
            sb.AppendLine($"# {c.Key}");
            sb.AppendLine();
            sb.AppendLine($"- Table: [[{c.Db}.{c.Schema}.{c.Table}]]");
            sb.AppendLine();
            sb.AppendLine("> Use backlinks to see which procs/views/functions read/write this column.");
            return sb.ToString();
        }

        static void Write(string path, string content) => File.WriteAllText(path, content, Encoding.UTF8);
    }
}
