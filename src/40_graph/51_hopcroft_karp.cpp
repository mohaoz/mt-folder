#include <bits/stdc++.h>
using namespace std;

// CIALLO_MD
// ## Hopcroft-Karp
// 二分图最大匹配。
//
// - 左部点 `1..n`，右部点 `1..m`；
// - `AddEdge(u, v)` 添加一条左部 `u` 到右部 `v` 的边；
// - `matchL[u]` 是左部点 `u` 匹配到的右部点；
// - 复杂度 `O(E \sqrt V)`。
// CIALLO_CODE
struct HopcroftKarp {
    int n, m;
    vector<vector<int>> adj;
    vector<int> matchL, matchR, dis;

    HopcroftKarp(int n, int m)
        : n(n), m(m), adj(n + 1), matchL(n + 1),
          matchR(m + 1), dis(n + 1) {}

    void AddEdge(int u, int v) {
        adj[u].emplace_back(v);
    }

    int Work() {
        int ans = 0;
        while (bfs()) {
            for (int u = 1; u <= n; u++)
                if (!matchL[u] and dfs(u))
                    ans++;
        }
        return ans;
    }

    bool bfs() {
        queue<int> q;
        fill(dis.begin(), dis.end(), -1);
        for (int u = 1; u <= n; u++) {
            if (!matchL[u]) {
                dis[u] = 0;
                q.emplace(u);
            }
        }
        bool found = false;
        while (!q.empty()) {
            int u = q.front();
            q.pop();
            for (int v : adj[u]) {
                int x = matchR[v];
                if (!x) {
                    found = true;
                } else if (dis[x] == -1) {
                    dis[x] = dis[u] + 1;
                    q.emplace(x);
                }
            }
        }
        return found;
    }

    bool dfs(int u) {
        for (int v : adj[u]) {
            int x = matchR[v];
            if (!x or (dis[x] == dis[u] + 1 and dfs(x))) {
                matchL[u] = v;
                matchR[v] = u;
                return true;
            }
        }
        dis[u] = -1;
        return false;
    }
};
// CIALLO_END

void P3386() {
    int n, m, e;
    cin >> n >> m >> e;
    HopcroftKarp hk(n, m);
    while (e--) {
        int u, v;
        cin >> u >> v;
        if (1 <= u and u <= n and 1 <= v and v <= m)
            hk.AddEdge(u, v);
    }
    cout << hk.Work() << '\n';
}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    P3386();
}
