using System;
using System.IO;

namespace DocuGen
{
    internal static class Program
    {
        public static int Main(string[] args)
        {
            try
            {
                var root = RepoLocator.FindRepoRoot(Directory.GetCurrentDirectory());
                var docuGenDir = RepoLocator.FindProjectDirNamed(root, "DocuGen");
                var outRoot = Path.Combine(docuGenDir, "docs", "generated", "obsidian");

                var dacpacs = DacpacFinder.FindAll(root);
                if (dacpacs.Count == 0)
                    throw new Exception("No .dacpac files found under repo. Build database projects so bin/** contains .dacpac outputs.");

                var catalog = DacFxCatalogLoader.Load(dacpacs);

                var sqlprojs = SqlProjScanner.FindSqlProjects(root);
                var sqlFilesByDb = SqlProjScanner.ReadSqlFiles(sqlprojs);

                ScriptDomColumnRefExtractor.Enrich(catalog, sqlFilesByDb);

                MarkdownEmitter.Emit(outRoot, catalog);

                Console.WriteLine($"Repo root: {root}");
                Console.WriteLine($"Dacpacs: {dacpacs.Count}");
                Console.WriteLine($"Databases: {catalog.Databases.Count}");
                Console.WriteLine($"Schemas: {catalog.Schemas.Count}");
                Console.WriteLine($"Objects: {catalog.Objects.Count}");
                Console.WriteLine($"Columns: {catalog.Columns.Count}");
                Console.WriteLine($"Output: {outRoot}");
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(ex.ToString());
                return 1;
            }
        }
    }
}
