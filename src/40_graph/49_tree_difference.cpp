#include <bits/stdc++.h>
using namespace std;

using i64 = int64_t;

// CIALLO_MD
// ## 树上差分
// 对树上路径做批量加法，再一次 DFS 汇总。
//
// - 默认点编号 `1..n`；
// - `AddVertexPath(u, v, w)` 给路径上的点加 `w`；
// - `AddEdgePath(u, v, w)` 给路径上的边加 `w`；
// - `Work()` 返回汇总后的差分值。对于边差分，边权存放在子节点上。
// CIALLO_CODE
struct TreeDifference {
    int n, LOG;
    vector<vector<int>> adj, up;
    vector<int> dep;
    vector<i64> diff;

    TreeDifference(const vector<vector<int>>& adj,
                   int root = 1)
        : n(adj.size() - 1), adj(adj),
          LOG(__lg(n) + 1), up(LOG, vector<int>(n + 1, root)),
          dep(n + 1), diff(n + 1) {
        auto dfs = [&](auto&& self, int u,
                       int p) -> void {
            up[0][u] = p;
            for (int i = 1; i < LOG; i++)
                up[i][u] = up[i - 1][up[i - 1][u]];
            for (int v : adj[u]) {
                if (v == p)
                    continue;
                dep[v] = dep[u] + 1;
                self(self, v, u);
            }
        };
        dfs(dfs, root, root);
    }

    void AddVertexPath(int u, int v,
                       i64 w = 1) {
        int g = lca(u, v);
        diff[u] += w;
        diff[v] += w;
        diff[g] -= w;
        if (up[0][g] != g)
            diff[up[0][g]] -= w;
    }

    void AddEdgePath(int u, int v,
                     i64 w = 1) {
        int g = lca(u, v);
        diff[u] += w;
        diff[v] += w;
        diff[g] -= 2 * w;
    }

    vector<i64> Work(int root = 1) {
        auto res = diff;
        auto dfs = [&](auto&& self, int u,
                       int p) -> void {
            for (int v : adj[u]) {
                if (v == p)
                    continue;
                self(self, v, u);
                res[u] += res[v];
            }
        };
        dfs(dfs, root, root);
        return res;
    }

    int jump(int u, int k) const {
        for (int i = 0; i < LOG; i++)
            if (k >> i & 1)
                u = up[i][u];
        return u;
    }

    int lca(int u, int v) const {
        if (dep[u] < dep[v])
            swap(u, v);
        u = jump(u, dep[u] - dep[v]);
        if (u == v)
            return u;
        for (int i = LOG - 1; i >= 0; i--) {
            if (up[i][u] != up[i][v]) {
                u = up[i][u];
                v = up[i][v];
            }
        }
        return up[0][u];
    }
};
// CIALLO_END

void VertexPathDemo() {
    int n, m;
    cin >> n >> m;
    vector adj(n + 1, vector<int>{});
    for (int i = 1; i < n; i++) {
        int u, v;
        cin >> u >> v;
        adj[u].emplace_back(v);
        adj[v].emplace_back(u);
    }
    TreeDifference td(adj);
    while (m--) {
        int u, v;
        cin >> u >> v;
        td.AddVertexPath(u, v);
    }
    auto cnt = td.Work();
    cout << *max_element(cnt.begin() + 1, cnt.end())
         << '\n';
}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    VertexPathDemo();
}
