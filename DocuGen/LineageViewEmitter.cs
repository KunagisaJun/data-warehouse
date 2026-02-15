using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace DocuGen
{
    internal static class LineageViewEmitter
    {
        const int MaxDepthObjects = 8;
        const int MaxDepthColumns = 6;
        const int MaxNodes = 800;

        enum EdgeKind { ReadObject, WriteObject, Call, ReadColumn, WriteColumn, Contains }

        sealed record Edge(string From, string To, EdgeKind Kind);

        public static void Emit(string outRoot, Catalog cat)
        {
            var viewsRoot = Path.Combine(outRoot, ".views");
            var upDir = Path.Combine(viewsRoot, "upstream");
            var downDir = Path.Combine(viewsRoot, "downstream");
            Directory.CreateDirectory(upDir);
            Directory.CreateDirectory(downDir);

            var edges = BuildEdges(cat);
            var outgoing = BuildAdjacency(edges, forward: true);
            var incoming = BuildAdjacency(edges, forward: false);

            foreach (var key in cat.Objects.Keys.OrderBy(k => k, StringComparer.OrdinalIgnoreCase))
            {
                Write(Path.Combine(upDir, $"{NameNorm.SafeFile(key)}.md"),
                    RenderClosure(key, incoming, isUpstream: true, maxDepth: MaxDepthObjects));
                Write(Path.Combine(downDir, $"{NameNorm.SafeFile(key)}.md"),
                    RenderClosure(key, outgoing, isUpstream: false, maxDepth: MaxDepthObjects));
            }

            foreach (var key in cat.Columns.Keys.OrderBy(k => k, StringComparer.OrdinalIgnoreCase))
            {
                Write(Path.Combine(upDir, $"{NameNorm.SafeFile(key)}.md"),
                    RenderClosure(key, incoming, isUpstream: true, maxDepth: MaxDepthColumns));
                Write(Path.Combine(downDir, $"{NameNorm.SafeFile(key)}.md"),
                    RenderClosure(key, outgoing, isUpstream: false, maxDepth: MaxDepthColumns));
            }
        }

        static List<Edge> BuildEdges(Catalog cat)
        {
            var edges = new List<Edge>(capacity: 4096);

            foreach (var o in cat.Objects.Values)
            {
                foreach (var src in o.ReadsObjects)
                    edges.Add(new Edge(src, o.Key, EdgeKind.ReadObject));

                foreach (var dst in o.WritesObjects)
                    edges.Add(new Edge(o.Key, dst, EdgeKind.WriteObject));

                foreach (var callee in o.CallsObjects)
                    edges.Add(new Edge(o.Key, callee, EdgeKind.Call));

                foreach (var srcCol in o.ReadsColumns)
                    edges.Add(new Edge(srcCol, o.Key, EdgeKind.ReadColumn));

                foreach (var dstCol in o.WritesColumns)
                    edges.Add(new Edge(o.Key, dstCol, EdgeKind.WriteColumn));
            }

            foreach (var c in cat.Columns.Values)
            {
                var tableKey = $"{c.Db}.{c.Schema}.{c.Table}";
                if (cat.Objects.ContainsKey(tableKey))
                    edges.Add(new Edge(tableKey, c.Key, EdgeKind.Contains));
            }

            return edges;
        }

        static Dictionary<string, List<Edge>> BuildAdjacency(List<Edge> edges, bool forward)
        {
            var map = new Dictionary<string, List<Edge>>(StringComparer.OrdinalIgnoreCase);
            foreach (var e in edges)
            {
                var key = forward ? e.From : e.To;
                if (!map.TryGetValue(key, out var list))
                    map[key] = list = new List<Edge>();
                list.Add(e);
            }

            foreach (var k in map.Keys.ToList())
                map[k] = map[k].OrderBy(x => forward ? x.To : x.From, StringComparer.OrdinalIgnoreCase).ToList();

            return map;
        }

        static string RenderClosure(string startKey, Dictionary<string, List<Edge>> adjacency, bool isUpstream, int maxDepth)
        {
            var sb = new StringBuilder();
            sb.AppendLine($"# {(isUpstream ? "Upstream" : "Downstream")}: {startKey}");
            sb.AppendLine();
            sb.AppendLine($"Start: [[{startKey}]]");
            sb.AppendLine();

            var visited = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { startKey };
            var frontier = new List<string> { startKey };

            for (var depth = 1; depth <= maxDepth; depth++)
            {
                if (frontier.Count == 0 || visited.Count >= MaxNodes)
                    break;

                var next = new List<string>();
                var lines = new List<string>();

                foreach (var cur in frontier)
                {
                    if (!adjacency.TryGetValue(cur, out var edges))
                        continue;

                    foreach (var e in edges)
                    {
                        var other = isUpstream ? e.From : e.To;
                        if (string.Equals(other, cur, StringComparison.OrdinalIgnoreCase))
                            continue;

                        if (!visited.Contains(other))
                        {
                            visited.Add(other);
                            next.Add(other);
                        }

                        lines.Add($"- [[{other}]] ({Describe(e.Kind)})");
                        if (visited.Count >= MaxNodes) break;
                    }
                    if (visited.Count >= MaxNodes) break;
                }

                if (lines.Count == 0)
                    break;

                sb.AppendLine($"## Hop {depth}");
                foreach (var line in lines.Distinct(StringComparer.OrdinalIgnoreCase))
                    sb.AppendLine(line);
                sb.AppendLine();

                frontier = next;
            }

            if (visited.Count >= MaxNodes)
                sb.AppendLine($"> Truncated at {MaxNodes} nodes.");

            return sb.ToString();
        }

        static string Describe(EdgeKind k) => k switch
        {
            EdgeKind.ReadObject => "read",
            EdgeKind.WriteObject => "write",
            EdgeKind.Call => "call",
            EdgeKind.ReadColumn => "read-col",
            EdgeKind.WriteColumn => "write-col",
            EdgeKind.Contains => "contains",
            _ => "edge"
        };

        static void Write(string path, string content) => File.WriteAllText(path, content, Encoding.UTF8);
    }
}
