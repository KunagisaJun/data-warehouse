using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Microsoft.SqlServer.Dac.Model;

namespace DocuGen
{
    internal static class DacFxCatalogLoader
    {
        public static Catalog Load(List<string> dacpacPaths)
        {
            var cat = new Catalog();

            foreach (var dacpac in dacpacPaths)
            {
                using var model = new TSqlModel(dacpac);

                var db = NameNorm.NormalizeDb(Path.GetFileNameWithoutExtension(dacpac));
                cat.Databases.Add(db);

                // Tables + Columns
                foreach (var t in model.GetObjects(DacQueryScopes.All, ModelSchema.Table))
                {
                    var (schema, table) = Split2(t.Name);
                    if (string.IsNullOrWhiteSpace(table)) continue;

                    cat.Schemas.Add((db, schema));

                    var tableKey = $"{db}.{schema}.{table}";
                    cat.Objects.TryAdd(tableKey, new SqlObject
                    {
                        Db = db,
                        Schema = schema,
                        Name = table,
                        Type = SqlObjectType.Table,
                        Key = tableKey
                    });

                    foreach (var c in t.GetChildren(DacQueryScopes.All).Where(x => x.ObjectType == ModelSchema.Column))
                    {
                        var colName = c.Name.Parts.LastOrDefault() ?? "";
                        if (string.IsNullOrWhiteSpace(colName)) continue;

                        var colKey = $"{db}.{schema}.{table}.{colName}";
                        cat.Columns.TryAdd(colKey, new SqlColumn
                        {
                            Db = db,
                            Schema = schema,
                            Table = table,
                            Name = colName,
                            Key = colKey
                        });
                    }
                }

                // Views / Procs / Functions
                AddObjects(model, db, ModelSchema.View, SqlObjectType.View, cat);
                AddObjects(model, db, ModelSchema.Procedure, SqlObjectType.Proc, cat);

                // Functions are split in DacFx
                AddObjects(model, db, ModelSchema.ScalarFunction, SqlObjectType.Function, cat);
                AddObjects(model, db, ModelSchema.TableValuedFunction, SqlObjectType.Function, cat);
            }

            return cat;
        }

        static void AddObjects(TSqlModel model, string db, ModelTypeClass tc, SqlObjectType type, Catalog cat)
        {
            foreach (var o in model.GetObjects(DacQueryScopes.All, tc))
            {
                var (schema, name) = Split2(o.Name);
                if (string.IsNullOrWhiteSpace(name)) continue;

                cat.Schemas.Add((db, schema));

                var key = $"{db}.{schema}.{name}";
                cat.Objects.TryAdd(key, new SqlObject
                {
                    Db = db,
                    Schema = schema,
                    Name = name,
                    Type = type,
                    Key = key
                });
            }
        }

        static (string Schema, string Name) Split2(ObjectIdentifier id)
        {
            // Typically: [schema].[name]
            // id.Parts is IList<string>
            var parts = id.Parts;
            var n = parts?.Count ?? 0;

            var schema = n >= 2 ? parts[n - 2] : "dbo";
            var name = n >= 1 ? parts[n - 1] : "";

            return (schema, name);
        }
    }
}
