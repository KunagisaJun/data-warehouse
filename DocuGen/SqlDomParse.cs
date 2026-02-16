using System;
using System.IO;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace DocuGen
{
    internal static class SqlDomParse
    {
        public static TSqlFragment? ParseFile(string path)
        {
            var parser = new TSql150Parser(initialQuotedIdentifiers: true);
            var text = File.ReadAllText(path);
            var frag = parser.Parse(new StringReader(text), out var errors);

            if (errors.Count == 0) return frag;

            Console.Error.WriteLine($"[DocuGen] ScriptDom parse errors in {path}:");
            var n = Math.Min(errors.Count, 10);
            for (var i = 0; i < n; i++)
                Console.Error.WriteLine($"  - {errors[i].Message} (line {errors[i].Line}, col {errors[i].Column})");
            if (errors.Count > n)
                Console.Error.WriteLine($"  - ... and {errors.Count - n} more");

            return null;
        }
    }
}
