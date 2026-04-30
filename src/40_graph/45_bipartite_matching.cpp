#include <bits/stdc++.h>
using namespace std;

// CIALLO_MD
// ## 二分图最大匹配
// 匈牙利算法。
//
// - 左部点 `1..n`，右部点 `1..m`；
// - `adj[u]` 存储左部点 `u` 能匹配的右部点；
// - 复杂度 `O(nm)`，稀疏图通常够用。
// CIALLO_CODE
int BipartiteMatching(const vector<vector<int>> &adj, int n, int m) {
    vector<int> mt(m + 1), vis(m + 1);
    int ans = 0, stamp = 0;
    auto dfs = [&](this auto &&self, int u) -> bool {
        for (int v : adj[u]) {
            if (vis[v] == stamp)
                continue;
            vis[v] = stamp;
            if (!mt[v] or self(mt[v])) {
                mt[v] = u;
                return true;
            }
        }
        return false;
    };
    for (int i = 1; i <= n; i++) {
        stamp++;
        ans += dfs(i);
    }
    return ans;
}
// CIALLO_END

void P3386() {
    int n, m, e;
    cin >> n >> m >> e;
    vector adj(n + 1, vector<int>{});
    while (e--) {
        int u, v;
        cin >> u >> v;
        if (1 <= u and u <= n and 1 <= v and v <= m)
            adj[u].emplace_back(v);
    }
    cout << BipartiteMatching(adj, n, m) << '\n';
}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    P3386();
}
