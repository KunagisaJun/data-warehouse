using System;
using System.IO;
using System.Linq;

namespace DocuGen
{
	internal static class RepoLocator
	{
		public static string FindRepoRoot(string startDir)
		{
			var dir = new DirectoryInfo(startDir);
			while (dir != null)
			{
				if (Directory.Exists(Path.Combine(dir.FullName, ".git")))
					return dir.FullName;

				if (dir.GetFiles("*.sln").Any() || dir.GetFiles("*.slnx").Any())
					return dir.FullName;

				dir = dir.Parent;
			}

			throw new Exception("No repo root (.git) or solution file found walking up from current directory.");
		}

		public static string FindProjectDirNamed(string rootDir, string projectName)
		{
			var csproj = Directory.EnumerateFiles(rootDir, $"{projectName}.csproj", SearchOption.AllDirectories).First();
			return Path.GetDirectoryName(csproj)!;
		}
	}
}
