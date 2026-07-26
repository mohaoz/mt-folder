#import "../../template.typ": snippet, web-only

== 割点
Tarjan 求无向图割点。

- 默认点编号 `1..n`；
- 返回所有割点；
- 复杂度 `O(n + m)`。

#let cut-vertex = ```cpp
auto CutVertex(const vector<vector<int>>& adj,
               int n) {
    vector<int> dfn(n + 1), low(n + 1), cut(n + 1),
        res;
    int now = 0;
    auto dfs = [&](auto&& self, int u,
                   int p) -> void {
        dfn[u] = low[u] = ++now;
        int child = 0;
        for (int v : adj[u]) {
            if (!dfn[v]) {
                child++;
                self(self, v, u);
                low[u] = min(low[u], low[v]);
                if (p != 0 and low[v] >= dfn[u])
                    cut[u] = true;
            } else if (v != p) {
                low[u] = min(low[u], dfn[v]);
            }
        }
        if (p == 0 and child >= 2)
            cut[u] = true;
    };
    for (int i = 1; i <= n; i++)
        if (!dfn[i])
            dfs(dfs, i, 0);
    for (int i = 1; i <= n; i++)
        if (cut[i])
            res.emplace_back(i);
    return res;
}
```

#snippet(cut-vertex)
