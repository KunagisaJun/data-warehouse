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

                foreach (var t in model.GetObjects(DacQueryScopes.All, ModelSchema.Table))
                {
                    var (schema, table) = Split2(t.Name);
                    if (table.Length == 0) continue;

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
                        if (colName.Length == 0) continue;

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

                AddObjects(model, db, ModelSchema.View, SqlObjectType.View, cat);
                AddObjects(model, db, ModelSchema.Procedure, SqlObjectType.Proc, cat);
                AddObjects(model, db, ModelSchema.Function, SqlObjectType.Function, cat);
            }

            return cat;
        }

        static void AddObjects(TSqlModel model, string db, ModelTypeClass tc, SqlObjectType type, Catalog cat)
        {
            foreach (var o in model.GetObjects(DacQueryScopes.All, tc))
            {
                var (schema, name) = Split2(o.Name);
                if (name.Length == 0) continue;

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
            var parts = id.Parts;
            var schema = parts.Length >= 2 ? parts[^2] : "dbo";
            var name = parts.Length >= 1 ? parts[^1] : "";
            return (schema, name);
        }
    }
}
