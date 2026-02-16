using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Collections.Generic;

namespace DocuGen
{
    internal static class MarkdownEmitter
    {
        const string ParentSectionObject = "## zc-plugin-parent-node";
        const string ParentSectionData = "## zc-plugin-parent-node-data";

        // IMPORTANT: no BOM.
        static readonly Encoding Utf8NoBom = new UTF8Encoding(encoderShouldEmitUTF8Identifier: false);

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

            foreach (var s in cat.Schemas
                                 .OrderBy(x => x.Db, StringComparer.OrdinalIgnoreCase)
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
            // Generator-owned stable tags only. Plugin adds lineage/* tags at runtime.
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
            if (t.Any(ch => char.IsWhiteSpace(ch) || ch == ':' || ch == '[' || ch == ']' || ch == ',' || ch == '"' || ch == '\''))
                return $"\"{t.Replace("\"", "\\\"")}\"";
            return t;
        }

        static void EmitParentSection(StringBuilder sb, string header, IEnumerable<string> parents)
        {
            // Always emit headings even when empty.
            sb.AppendLine(header);
            foreach (var p in parents.Where(x => !string.IsNullOrWhiteSpace(x))
                                     .Distinct(StringComparer.OrdinalIgnoreCase)
                                     .OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
            {
                sb.AppendLine($"- [[{p}]]");
            }
            sb.AppendLine();
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

            EmitParentSection(sb, ParentSectionObject, Array.Empty<string>());
            EmitParentSection(sb, ParentSectionData, Array.Empty<string>());

            return sb.ToString();
        }

        static string RenderSchema(string db, string schema, Catalog cat)
        {
            var key = $"{db}.{schema}";
            var sb = new StringBuilder();
            sb.Append(Yaml(key, "schema", db));
            sb.AppendLine($"# {db}.{schema}");
            sb.AppendLine();

            sb.AppendLine("## Objects");
            foreach (var o in cat.Objects.Values.Where(o =>
                         db.Equals(o.Db, StringComparison.OrdinalIgnoreCase) &&
                         schema.Equals(o.Schema, StringComparison.OrdinalIgnoreCase))
                     .OrderBy(o => o.Type)
                     .ThenBy(o => o.Name, StringComparer.OrdinalIgnoreCase))
                sb.AppendLine($"- [[{o.Key}]]");
            sb.AppendLine();

            // Object graph containment
            EmitParentSection(sb, ParentSectionObject, new[] { db });

            // Data graph: schema has no data parents
            EmitParentSection(sb, ParentSectionData, Array.Empty<string>());

            return sb.ToString();
        }

        static string RenderObject(SqlObject o, Catalog cat)
        {
            var typeTag = o.Type.ToString().ToLowerInvariant();
            var schemaKey = $"{o.Db}.{o.Schema}";

            var sb = new StringBuilder();
            sb.Append(Yaml(o.Key, typeTag, o.Db));
            sb.AppendLine($"# {o.Key}");
            sb.AppendLine();

            sb.AppendLine($"- Schema: [[{schemaKey}]]");
            sb.AppendLine($"- Type: `{o.Type}`");
            sb.AppendLine();

            if (!string.IsNullOrWhiteSpace(o.DefinitionSql))
            {
                sb.AppendLine("## Definition");
                sb.AppendLine("```sql");
                sb.AppendLine(o.DefinitionSql.TrimEnd());
                sb.AppendLine("```");
                sb.AppendLine();
            }

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

                EmitParentSection(sb, ParentSectionObject, new[] { schemaKey });
                // Data graph: include upstream tables/cols and loader procs when populated.
                EmitParentSection(sb, ParentSectionData, o.DataParents);
                return sb.ToString();
            }

            // Object lineage parents: containment + object deps (keep columns out to avoid wide closure)
            var objParents = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { schemaKey };
            objParents.UnionWith(o.ReadsObjects);
            objParents.UnionWith(o.WritesObjects);
            objParents.UnionWith(o.CallsObjects);

            EmitParentSection(sb, ParentSectionObject, objParents);

            // Data lineage: include upstream tables/cols when populated.
            EmitParentSection(sb, ParentSectionData, o.DataParents);

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

            // Object graph: containment
            EmitParentSection(sb, ParentSectionObject, new[] { $"{c.Db}.{c.Schema}.{c.Table}" });

            // Data graph: true column lineage parents (upstream columns)
            EmitParentSection(sb, ParentSectionData, c.DataParents);

            return sb.ToString();
        }

        static void Write(string path, string content) =>
            File.WriteAllText(path, content, Utf8NoBom);
    }
}
