#import "../../template.typ": snippet, web-only

== 二分图最大匹配
匈牙利算法。

- 左部点 `1..n`，右部点 `1..m`；
- `adj[u]` 存储左部点 `u` 能匹配的右部点；
- 复杂度 `O(nm)`，稀疏图通常够用。

#let bipartite-matching = ```cpp
auto BipartiteMatching(
    const vector<vector<int>>& adj, int n, int m) {
    vector<int> mt(m + 1), vis(m + 1);
    int ans = 0, stamp = 0;
    auto dfs = [&](auto&& self,
                   int u) -> bool {
        for (int v : adj[u]) {
            if (vis[v] == stamp)
                continue;
            vis[v] = stamp;
            if (!mt[v] or self(self, mt[v])) {
                mt[v] = u;
                return true;
            }
        }
        return false;
    };
    for (int i = 1; i <= n; i++) {
        stamp++;
        ans += dfs(dfs, i);
    }
    return ans;
}
```

#snippet(bipartite-matching, header: "graph/bipartite_matching.hpp")
