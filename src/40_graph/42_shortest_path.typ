#import "../../template.typ": snippet, web-only

== 分层图最短路
适用于非负边权图上最多使用 $k$ 次特殊操作。

`P4568` 的建模方式：

- $"dist"[u][i]$ 表示到达点 $u$，且已经用了 $i$ 次免费机会的最小代价；
- 走普通边：$(u, i) arrow.r (v, i)$，边权为 $w$；
- 若 $i < k$，则可以免费走这条边：$(u, i) arrow.r (v, i + 1)$，边权为 $0$；
- 答案为 $min_(0 <= i <= k) "dist"[t][i]$。

复杂度 $O((n k + m k) log(n k))$。

#let layered-dijkstra = ```cpp
auto LayeredDijkstra(
    const vector<vector<pair<int, int>>>& adj,
    int n, int s, int k) {
    using i64 = int64_t;
    constexpr i64 INF = 4'000'000'000'000'000'000LL;
    vector dist(n + 1, vector<i64>(k + 1, INF));
    priority_queue<tuple<i64, int, int>> pq;
    dist[s][0] = 0;
    pq.emplace(0, s, 0);
    while (!pq.empty()) {
        auto [d, u, used] = pq.top();
        pq.pop();
        d = -d;
        if (d != dist[u][used])
            continue;
        for (auto [v, w] : adj[u]) {
            if (dist[u][used] + w < dist[v][used]) {
                dist[v][used] = dist[u][used] + w;
                pq.emplace(-dist[v][used], v, used);
            }
            if (used < k and
                dist[u][used] < dist[v][used + 1]) {
                dist[v][used + 1] = dist[u][used];
                pq.emplace(-dist[v][used + 1], v,
                           used + 1);
            }
        }
    }
    return dist;
}
```

#snippet(layered-dijkstra)
