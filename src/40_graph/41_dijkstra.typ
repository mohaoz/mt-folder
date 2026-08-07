#import "../../template.typ": snippet, web-only

= 图论
== 图论通用约束

+ 使用 `vector<vector<int>> adj` 存储点编号为 `1..n` 的无权图；
  有向边只加入一个方向，无向边同时加入两个方向；
+ 使用 `vector<vector<pair<int, int>>> adj` 存储带权图，
  `pair.first` 为终点，`pair.second` 为边权；
+ 使用 `vector<pair<int, int>> es` 存储边，使用
  `vector<array<int, 3>> es` 存储带权边；根据语义也可以命名为
  `uv` 或 `uvw`；
+ 使用 `deg` 存储度数；只使用入度或出度之一时也可使用 `deg`，
  同时使用时分别命名为 `indeg` 和 `outdeg`；
+ 使用 `fa[u]` 表示点 `u` 的父亲节点。

== 单源最短路
适用于非负边权图。

- `adj[u]` 存储 `(v, w)`；
- 默认点编号为 `1..n`；
- 复杂度 `O((n + m) log n)`。

#let dijkstra = ```cpp
using i64 = int64_t;
constexpr i64 INF = 4'000'000'000'000'000'000LL;

auto dijkstra(
    const vector<vector<pair<int, int>>>& adj,
    int n, int s) {
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
