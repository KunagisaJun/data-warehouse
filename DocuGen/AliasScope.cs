using System;
using System.Collections.Generic;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace DocuGen
{
    internal sealed class AliasScope
    {
        readonly Dictionary<string, (string Db, string Schema, string Table)> _map;

        AliasScope(Dictionary<string, (string Db, string Schema, string Table)> map)
            => _map = map;

        public bool TryResolve(string aliasOrTableName, out (string Db, string Schema, string Table) table)
            => _map.TryGetValue(aliasOrTableName, out table);

        public static AliasScope Build(TSqlFragment node, string currentDb)
        {
            var map = new Dictionary<string, (string Db, string Schema, string Table)>(StringComparer.OrdinalIgnoreCase);
            node.Accept(new Collector(currentDb, map));
            return new AliasScope(map);
        }

        sealed class Collector : TSqlFragmentVisitor
        {
            readonly string _currentDb;
            readonly Dictionary<string, (string Db, string Schema, string Table)> _map;

            public Collector(string currentDb, Dictionary<string, (string Db, string Schema, string Table)> map)
            {
                _currentDb = currentDb;
                _map = map;
            }

            public override void Visit(NamedTableReference node)
            {
                var son = node.SchemaObject;
                var alias = node.Alias?.Value;

                var t = SqlNameResolver.TryResolveTableName(son, _currentDb);
                if (t != null)
                {
                    // explicit alias
                    if (!string.IsNullOrWhiteSpace(alias) && !alias.StartsWith("@", StringComparison.Ordinal))
                        _map[alias] = t.Value;

                    // base table name (so Table.Col works even without alias)
                    var baseName = son?.BaseIdentifier?.Value;
                    if (!string.IsNullOrWhiteSpace(baseName) && !_map.ContainsKey(baseName))
                        _map[baseName] = t.Value;
                }

                base.Visit(node);
            }
        }
    }
}
