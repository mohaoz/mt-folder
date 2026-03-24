#include <functional>
#include <queue>
#include <tuple>
#include <vector>

using i64 = long long;

// CIALLO_MD
// ## 分层图最短路
//
// 适用场景：
//
// - 原图最短路中额外带有一个“小状态”；
// - 常见形式是“最多使用 `k` 次特殊操作”；
// - 每次特殊操作只会让状态 `+1`，而不会影响最短路性质。
//
// `P4568` 的建模方式：
//
// - `dist[u][i]` 表示到达点 `u`，且已经用了 `i` 次免费机会的最小代价；
// - 走普通边：`(u, i) -> (v, i)`，边权为 `w`；
// - 若 `i < k`，则可以免费走这条边：`(u, i) -> (v, i + 1)`，边权为 `0`；
// - 答案为 `min(dist[t][0..k])`。
//
// 复杂度：`O((n k + m k) log(n k))`。
// CIALLO_CODE
struct LayeredShortestPath {
    struct Edge {
        int to, w;
    };

    int n;
    std::vector<std::vector<Edge>> adj;

    LayeredShortestPath(int n) : n(n), adj(n) {}

    void AddEdge(int u, int v, int w) {
        adj[u].push_back({v, w});
    }

    std::vector<std::vector<i64>> Dist(int s, int k) {
        static constexpr i64 INF = 4e18;
        std::vector dist(n, std::vector<i64>(k + 1, INF));
        std::priority_queue<
            std::tuple<i64, int, int>,
            std::vector<std::tuple<i64, int, int>>,
            std::greater<>
        > pq;

        dist[s][0] = 0;
        pq.emplace(0, s, 0);
        while (!pq.empty()) {
            auto [d, u, used] = pq.top();
            pq.pop();
            if (d != dist[u][used]) {
                continue;
            }
            for (auto [v, w] : adj[u]) {
                if (i64 nd = d + w; nd < dist[v][used]) {
                    dist[v][used] = nd;
                    pq.emplace(nd, v, used);
                }
                if (used < k and d < dist[v][used + 1]) {
                    dist[v][used + 1] = d;
                    pq.emplace(d, v, used + 1);
                }
            }
        }
        return dist;
    }
};
// CIALLO_END
