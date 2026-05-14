#include <bits/stdc++.h>
using namespace std;

// CIALLO_MD
// ## 强连通分量 (SCC)
// Tarjan 求有向图强连通分量。
//
// - 默认点编号 `1..n`；
// - `id[u]` 为 `u` 所在 SCC 编号；
// - 复杂度 `O(n + m)`。
// CIALLO_CODE
struct SCC {
    int n, now = 0, cnt = 0;
    vector<vector<int>> adj;
    vector<int> dfn, low, stk, ins, id;

    SCC(int n)
        : n(n), adj(n + 1), dfn(n + 1), low(n + 1),
          ins(n + 1), id(n + 1) {}

    void AddEdge(int u, int v) {
        adj[u].emplace_back(v);
    }

    void tarjan(int u) {
        dfn[u] = low[u] = ++now;
        stk.emplace_back(u);
        ins[u] = true;
        for (int v : adj[u]) {
            if (!dfn[v]) {
                tarjan(v);
                low[u] = min(low[u], low[v]);
            } else if (ins[v]) {
                low[u] = min(low[u], dfn[v]);
            }
        }
        if (dfn[u] == low[u]) {
            cnt++;
            while (true) {
                int x = stk.back();
                stk.pop_back();
                ins[x] = false;
                id[x] = cnt;
                if (x == u)
                    break;
            }
        }
    }

    std::pair<std::vector<int>, int> Work() {
        for (int i = 1; i <= n; i++)
            if (!dfn[i])
                tarjan(i);
        return {id, cnt};
    }
};
// CIALLO_END

void P3387() {
    int n, m;
    cin >> n >> m;
    vector<int> w(n + 1);
    for (int i = 1; i <= n; i++)
        cin >> w[i];
    SCC scc(n);
    vector<pair<int, int>> edges;
    while (m--) {
        int u, v;
        cin >> u >> v;
        scc.AddEdge(u, v);
        edges.emplace_back(u, v);
    }
    auto [id, cnt] = scc.Work();
    vector<int> val(cnt + 1), indeg(cnt + 1),
        dp(cnt + 1);
    vector dag(cnt + 1, vector<int>{});
    set<pair<int, int>> vis;
    for (int i = 1; i <= n; i++)
        val[id[i]] += w[i];
    for (auto [u, v] : edges) {
        u = id[u], v = id[v];
        if (u != v and !vis.count({u, v})) {
            dag[u].emplace_back(v);
            indeg[v]++;
            vis.emplace(u, v);
        }
    }
    queue<int> q;
    for (int i = 1; i <= cnt; i++) {
        dp[i] = val[i];
        if (!indeg[i])
            q.emplace(i);
    }
    while (!q.empty()) {
        int u = q.front();
        q.pop();
        for (int v : dag[u]) {
            dp[v] = max(dp[v], dp[u] + val[v]);
            if (--indeg[v] == 0)
                q.emplace(v);
        }
    }
    cout << *max_element(dp.begin() + 1, dp.end())
         << '\n';
}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    P3387();
}
