#import "../../template.typ": snippet, web-only

== LCA
倍增求树上最近公共祖先。

- 默认点编号 `1..n`；
- `adj` 是无向树；
- `Get(u, v)` 返回 `u` 和 `v` 的 LCA；
- `Dis(u, v)` 返回 `u` 和 `v` 的距离；
- `Kth(u, v, k)` 返回从 `u` 到 `v` 路径上的第 `k` 个点，`k` 从 `0` 开始；
- `Component(u, v)` 返回删掉点 `u` 后 `v` 所在连通块的大小，要求 `u` 和 `v` 相邻；
- 预处理复杂度 `O(n log n)`，单次查询 `O(log n)`。

#let lca = ```cpp
struct LCA {
    int n, LOG;
    vector<int> dep, siz;
    vector<vector<int>> up;

    LCA(const vector<vector<int>>& adj, int root = 1) {
        n = adj.size() - 1;
        LOG = __lg(n) + 1;
        dep.assign(n + 1, 0);
        siz.assign(n + 1, 1);
        up.assign(LOG, vector<int>(n + 1, root));

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
                siz[u] += siz[v];
            }
        };
        dfs(dfs, root, root);
    }

    int Get(int u, int v) const {
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

    int Dis(int u, int v) const {
        int g = Get(u, v);
        return dep[u] + dep[v] - 2 * dep[g];
    }

    int Kth(int u, int v, int k) const {
        int g = Get(u, v);
        int du = dep[u] - dep[g];
        int d = du + dep[v] - dep[g];
        if (k <= du)
            return jump(u, k);
        return jump(v, d - k);
    }

    int Component(int u, int v) const {
        if (up[0][v] == u)
            return siz[v];
        return n - siz[u];
    }

    int jump(int u, int k) const {
        for (int i = 0; i < LOG; i++)
            if (k >> i & 1)
                u = up[i][u];
        return u;
    }
};
```

#snippet(lca, id: "lca")
