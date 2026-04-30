#include <bits/stdc++.h>
using namespace std;

// CIALLO_MD
// ## 割点
// Tarjan 求无向图割点。
//
// - 默认点编号 `1..n`；
// - 返回所有割点；
// - 复杂度 `O(n + m)`。
// CIALLO_CODE
vector<int> CutVertex(const vector<vector<int>> &adj, int n) {
    vector<int> dfn(n + 1), low(n + 1), cut(n + 1), res;
    int now = 0;
    auto Dfs = [&](this auto &&self, int u, int p) -> void {
        dfn[u] = low[u] = ++now;
        int child = 0;
        for (int v : adj[u]) {
            if (!dfn[v]) {
                child++;
                self(v, u);
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
            Dfs(i, 0);
    for (int i = 1; i <= n; i++)
        if (cut[i])
            res.emplace_back(i);
    return res;
}
// CIALLO_END

void P3388() {
    int n, m;
    cin >> n >> m;
    vector adj(n + 1, vector<int>{});
    while (m--) {
        int u, v;
        cin >> u >> v;
        adj[u].emplace_back(v);
        adj[v].emplace_back(u);
    }
    auto ans = CutVertex(adj, n);
    cout << ans.size() << '\n';
    for (int x : ans)
        cout << x << ' ';
    cout << '\n';
}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    P3388();
}
