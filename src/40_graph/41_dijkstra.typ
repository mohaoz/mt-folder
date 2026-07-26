#import "../../template.typ": snippet, web-only

= 图论
== 单源最短路
适用于非负边权图。

- `adj[u]` 存储 `(v, w)`；
- 默认点编号为 `1..n`；
- 复杂度 `O((n + m) log n)`。

#let dijkstra = ```cpp
using i64 = int64_t;
constexpr i64 INF = 4'000'000'000'000'000'000LL;

template <class Adj>
auto dijkstra(const Adj& adj, int n, int s) {
    vector<i64> dis(n + 1, INF);
    vector<bool> vis(n + 1, false);
    priority_queue<pair<i64, int>> pq;
    dis[s] = 0;
    pq.emplace(0, s);
    while (!pq.empty()) {
        auto [_, u] = pq.top();
        pq.pop();
        if (vis[u])
            continue;
        vis[u] = true;
        for (auto [v, w] : adj[u]) {
            if (dis[u] + w < dis[v]) {
                dis[v] = dis[u] + w;
                pq.emplace(-dis[v], v);
            }
        }
    }
    return dis;
}
```

#snippet(dijkstra, id: "dijkstra")
