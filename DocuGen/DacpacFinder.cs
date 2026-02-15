using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace DocuGen
{
    internal static class DacpacFinder
    {
        public static List<string> FindAll(string rootDir) =>
            Directory.EnumerateFiles(rootDir, "*.dacpac", SearchOption.AllDirectories)
                .Select(Path.GetFullPath)
                .Where(p =>
                {
                    try { return new FileInfo(p).Length > 0; }
                    catch { return false; }
                })
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(p => p, StringComparer.OrdinalIgnoreCase)
                .ToList();
    }
}
