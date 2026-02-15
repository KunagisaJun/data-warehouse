using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;

namespace DocuGen
{
    internal static class SqlProjScanner
    {
        public static List<string> FindSqlProjects(string rootDir) =>
            Directory.EnumerateFiles(rootDir, "*.sqlproj", SearchOption.AllDirectories)
                .Select(Path.GetFullPath)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

        // DB(project name) -> sql file list
        public static Dictionary<string, List<string>> ReadSqlFiles(List<string> sqlprojPaths)
        {
            var map = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);

            foreach (var sqlproj in sqlprojPaths)
            {
                var db = Path.GetFileNameWithoutExtension(sqlproj);
                var projDir = Path.GetDirectoryName(sqlproj)!;

                var files = ReadBuildIncludes(sqlproj)
                    .Select(p => Path.GetFullPath(Path.Combine(projDir, p)))
                    .Where(File.Exists)
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .ToList();

                if (!map.TryGetValue(db, out var list))
                    map[db] = list = new List<string>();

                list.AddRange(files);
            }

            foreach (var kv in map)
                kv.Value.Sort(StringComparer.OrdinalIgnoreCase);

            return map;
        }

        static IEnumerable<string> ReadBuildIncludes(string sqlprojPath)
        {
            var doc = XDocument.Load(sqlprojPath);
            return doc.Descendants()
                .Where(e => e.Name.LocalName == "Build")
                .Select(e => (string?)e.Attribute("Include"))
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .Select(p => p!.Replace('\\', Path.DirectorySeparatorChar))
                .Where(p => p.EndsWith(".sql", StringComparison.OrdinalIgnoreCase));
        }
    }
}
