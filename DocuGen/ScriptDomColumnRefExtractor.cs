using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace DocuGen
{
	internal static class ScriptDomColumnRefExtractor
	{
		public static void Enrich(Catalog cat, Dictionary<string, List<string>> sqlFilesByDb)
		{
			foreach (var (dbRaw, files) in sqlFilesByDb)
			{
				var db = NameNorm.NormalizeDb(dbRaw);

				foreach (var file in files)
				{
					var frag = Parse(file);
					if (frag == null) continue;

					var def = new DefinitionVisitor(db);
					frag.Accept(def);
					if (def.DefinedObjectKeys.Count == 0) continue;

					var refs = new ColumnRefVisitor(cat);
					frag.Accept(refs);

					foreach (var objKey in def.DefinedObjectKeys)
					{
						if (!cat.Objects.TryGetValue(objKey, out var obj)) continue;
						if (obj.Type == SqlObjectType.Table) continue;
						obj.ReferencedColumns.UnionWith(refs.ReferencedColumns);
					}
				}
			}
		}

		static TSqlFragment? Parse(string path)
		{
			var parser = new TSql150Parser(true);
			var frag = parser.Parse(new StringReader(File.ReadAllText(path)), out var errors);
			return errors.Count == 0 ? frag : null;
		}

		sealed class DefinitionVisitor : TSqlFragmentVisitor
		{
			readonly string _db;
			public HashSet<string> DefinedObjectKeys { get; } = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
			public DefinitionVisitor(string db) => _db = db;

			public override void Visit(CreateProcedureStatement node) => Add(GetProcName(node));
			public override void Visit(CreateViewStatement node) => Add(node.SchemaObjectName);
			public override void Visit(CreateFunctionStatement node) => Add(node.Name);
			public override void Visit(CreateTableStatement node) => Add(node.SchemaObjectName);

			void Add(SchemaObjectName? son)
			{
				if (son == null) return;
				var schema = son.SchemaIdentifier?.Value ?? "dbo";
				var name = son.BaseIdentifier?.Value ?? "";
				if (name.Length == 0) return;
				DefinedObjectKeys.Add($"{_db}.{schema}.{name}");
			}

			// If this doesn't compile in your ScriptDom version, tell me; I’ll swap to a reflection-based getter.
			static SchemaObjectName? GetProcName(CreateProcedureStatement node)
				=> node.ProcedureReference?.Name;
		}

		sealed class ColumnRefVisitor : TSqlFragmentVisitor
		{
			readonly Catalog _cat;
			public HashSet<string> ReferencedColumns { get; } = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
			public ColumnRefVisitor(Catalog cat) => _cat = cat;

			public override void Visit(ColumnReferenceExpression node)
			{
				var ids = node.MultiPartIdentifier?.Identifiers;
				if (ids == null || ids.Count != 4) { base.Visit(node); return; }

				var db = NameNorm.NormalizeDb(ids[0].Value);
				var schema = ids[1].Value;
				var table = ids[2].Value;
				var col = ids[3].Value;

				var key = $"{db}.{schema}.{table}.{col}";
				if (_cat.Columns.ContainsKey(key))
					ReferencedColumns.Add(key);

				base.Visit(node);
			}
		}
	}
}
