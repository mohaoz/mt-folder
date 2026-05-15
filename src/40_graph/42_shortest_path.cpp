#include <bits/stdc++.h>
using namespace std;

using i64 = int64_t;
constexpr i64 INF = 1'000'000'000'000'000'000LL;

// CIALLO_MD
// ## 分层图最短路
// 适用于非负边权图上最多使用 `k` 次特殊操作。
//
// `P4568` 的建模方式：
//
// - `dist[u][i]` 表示到达点 `u`，且已经用了 `i` 次免费机会的最小代价；
// - 走普通边：`(u, i) -> (v, i)`，边权为 `w`；
// - 若 `i < k`，则可以免费走这条边：`(u, i) -> (v, i + 1)`，边权为 `0`；
// - 答案为 `min(dist[t][0..k])`。
//
// 复杂度 `O((n k + m k) log(n k))`。
// CIALLO_CODE
template <class Adj>
auto LayeredDijkstra(const Adj& adj, int n, int s,
                     int k) {
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
// CIALLO_END

void P4568() {
    int n, m, k, s, t;
    cin >> n >> m >> k >> s >> t;
    s++, t++;
    vector adj(n + 1, vector<pair<int, int>>{});
    while (m--) {
        int u, v, w;
        cin >> u >> v >> w;
        u++, v++;
        adj[u].emplace_back(v, w);
        adj[v].emplace_back(u, w);
    }
    auto dist = LayeredDijkstra(adj, n, s, k);
    cout << *min_element(dist[t].begin(),
                         dist[t].end())
         << '\n';
}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    P4568();
}
