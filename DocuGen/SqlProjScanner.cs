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
                .OrderBy(p => p, StringComparer.OrdinalIgnoreCase)
                .ToList();

        // DB(project name) -> sql file list
        public static Dictionary<string, List<string>> ReadSqlFiles(List<string> sqlprojPaths)
        {
            var map = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);

            foreach (var sqlproj in sqlprojPaths)
            {
                var db = Path.GetFileNameWithoutExtension(sqlproj);
                var projDir = Path.GetDirectoryName(sqlproj)!;

                var includes = ReadBuildIncludes(sqlproj).ToList();
                var files = includes.Count > 0
                    ? includes.Select(p => Path.GetFullPath(Path.Combine(projDir, p)))
                             .Where(File.Exists)
                             .ToList()
                    : EnumerateSqlFilesForSdkStyleProject(projDir).ToList();

                if (!map.TryGetValue(db, out var list))
                {
                    list = new List<string>();
                    map[db] = list;
                }

                list.AddRange(files);
            }

            // IMPORTANT: KeyValuePair.Value is read-only; reassign via map[key]
            foreach (var db in map.Keys.ToList())
            {
                map[db] = map[db]
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .OrderBy(p => p, StringComparer.OrdinalIgnoreCase)
                    .ToList();
            }

            return map;
        }

        static IEnumerable<string> ReadBuildIncludes(string sqlprojPath)
        {
            try
            {
                var doc = XDocument.Load(sqlprojPath);

                // Match by LocalName (default namespace in sqlproj)
                return doc.Descendants()
                    .Where(e => e.Name.LocalName == "Build")
                    .Select(e => (string?)e.Attribute("Include"))
                    .Where(p => !string.IsNullOrWhiteSpace(p))
                    .Select(p => p!.Replace('\\', Path.DirectorySeparatorChar))
                    .Where(p => p.EndsWith(".sql", StringComparison.OrdinalIgnoreCase));
            }
            catch
            {
                return Array.Empty<string>();
            }
        }

        static IEnumerable<string> EnumerateSqlFilesForSdkStyleProject(string projectDir)
        {
            return Directory.EnumerateFiles(projectDir, "*.sql", SearchOption.AllDirectories)
                .Select(Path.GetFullPath)
                .Where(p => !IsUnder(p, projectDir, "bin"))
                .Where(p => !IsUnder(p, projectDir, "obj"))
                .Where(p => !IsUnder(p, projectDir, ".vs"))
                .Where(p => !p.EndsWith(".refactorlog", StringComparison.OrdinalIgnoreCase));
        }

        static bool IsUnder(string fullPath, string rootDir, string folderName)
        {
            var root = Path.GetFullPath(rootDir).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            var path = Path.GetFullPath(fullPath);

            if (!path.StartsWith(root, StringComparison.OrdinalIgnoreCase))
                return false;

            var rel = path.Substring(root.Length);
            var prefix = folderName.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;

            return rel.StartsWith(prefix, StringComparison.OrdinalIgnoreCase);
        }
    }
}
