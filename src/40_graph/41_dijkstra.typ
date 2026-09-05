#import "../../template.typ": snippet, web-only

== 图论通用约束

+ 使用 `vector<vector<int>> adj` 存储点编号为 $1 dots n$ 的无权图；
  有向边只加入一个方向，无向边同时加入两个方向；
+ 使用 `vector<vector<pair<int, int>>> adj` 存储带权图，
  `pair.first` 为终点，`pair.second` 为边权；
+ 使用 `vector<pair<int, int>> es` 存储边，使用
  `vector<array<int, 3>> es` 存储带权边；根据语义也可以命名为
  `uv` 或 `uvw`；
+ 使用 `deg` 存储度数；只使用入度或出度之一时也可使用 `deg`，
  同时使用时分别命名为 `indeg` 和 `outdeg`；
+ 使用 `fa[u]` 表示点 `u` 的父亲节点。

== 最短路

=== Dijkstra
适用于非负边权图。

- `adj[u]` 存储 `(v, w)`；
- 默认点编号为 $1 dots n$；
- 复杂度 $O((n + m) log n)$。

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

=== 0-1 BFS
适用于边权仅为 $0$ 或 $1$ 的单源最短路。

- `adj[u]` 存储 `(v, w)`，且必须满足 $w = 0$ 或 $w = 1$；
- 默认点编号为 $1 dots n$，返回到各点的最短距离；不可达点为 `1e9`；
- 复杂度 $O(n + m)$，额外空间 $O(n)$。

#let zero-one-bfs = ```cpp
auto BFS01(
    const vector<vector<pair<int, int>>>& adj,
    int n, int s) {
    constexpr int INF = 1'000'000'000;
    vector<int> dis(n + 1, INF);
    vector<bool> vis(n + 1, false);
    deque<int> dq;
    dis[s] = 0;
    dq.push_back(s);
    while (!dq.empty()) {
        int u = dq.front();
        dq.pop_front();
        if (vis[u])
            continue;
        vis[u] = true;
        for (auto [v, w] : adj[u]) {
            if (dis[u] + w < dis[v]) {
                dis[v] = dis[u] + w;
                if (w == 0)
                    dq.push_front(v);
                else
                    dq.push_back(v);
            }
        }
    }
    return dis;
}
```

#snippet(zero-one-bfs, id: "zero-one-bfs")

=== 多源初始化
设源点集合为 $S$，求它到每个点的最短距离：

$ "dis"[v] = min_(s in S) "dist"(s, v) $

这等价于新建一个超级源点，并向所有源点连 $0$ 权边；
实现时无需真正建点，代码中的源点集合记为 `sources`。

算法主体不变，只把单源初始化替换为：

- 普通 BFS：对每个 `s` 设 `dis[s] = 0`、`vis[s] = true`，然后
  `q.push(s)`；
- 0-1 BFS：对每个 `s` 设 `dis[s] = 0`，然后 `dq.push_back(s)`；
- Dijkstra：对每个 `s` 设 `dis[s] = 0`，然后 `pq.emplace(0, s)`。

若 `sources` 可能重复，初始化时先判断该点的距离是否已为 `0`。
这种做法只保留“距离最近的源点”的结果；若需要每个源点各自的距离，
仍需分别运行或使用全源最短路。
