// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/shortest_path

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int n, m, s, t;
    std::cin >> n >> m >> s >> t;
    ++s, ++t;

    std::vector<std::vector<std::pair<int, int>>> adj(n + 1);
    struct Edge {
        int from, to;
        int weight;
    };
    std::vector<Edge> edges;
    edges.reserve(m);
    for (int i = 0; i < m; ++i) {
        int a, b;
        int c;
        std::cin >> a >> b >> c;
        adj[a + 1].emplace_back(b + 1, c);
        edges.push_back({a + 1, b + 1, c});
    }

    const auto dis = mtf::dijkstra(adj, n, s);
    if (dis[t] >= mtf::INF) {
        std::cout << -1 << '\n';
        return 0;
    }

    // 权重可为 0（紧边可能成环），沿紧边从 s 做 BFS 建父指针，
    // 保证重建出的路径无环。
    std::vector<std::vector<int>> tight(n + 1);
    for (int i = 0; i < m; ++i) {
        const auto& [from, to, weight] = edges[i];
        if (dis[from] < mtf::INF && dis[from] + weight == dis[to])
            tight[from].push_back(to);
    }
    std::vector<int> fa(n + 1, 0);
    std::queue<int> queue;
    fa[s] = s;
    queue.push(s);
    while (!queue.empty() && fa[t] == 0) {
        int u = queue.front();
        queue.pop();
        for (int v : tight[u]) {
            if (fa[v] == 0) {
                fa[v] = u;
                queue.push(v);
            }
        }
    }

    std::vector<int> path;
    for (int u = t; u != s; u = fa[u])
        path.push_back(u);
    path.push_back(s);
    std::reverse(path.begin(), path.end());

    std::cout << dis[t] << ' ' << path.size() - 1 << '\n';
    for (std::size_t i = 0; i + 1 < path.size(); ++i)
        std::cout << path[i] - 1 << ' ' << path[i + 1] - 1 << '\n';
}
