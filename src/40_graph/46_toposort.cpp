#include <bits/stdc++.h>
using namespace std;

// CIALLO_MD
// ## 拓扑排序
// Kahn 算法。
//
// - 默认点编号 `1..n`；
// - 若返回数量小于 `n`，则图中有环；
// - 复杂度 `O(n + m)`。
// CIALLO_CODE
auto TopoSort(const vector<vector<int>>& adj,
              int n) {
    vector<int> indeg(n + 1), res;
    queue<int> q;
    for (int u = 1; u <= n; u++)
        for (int v : adj[u])
            indeg[v]++;
    for (int i = 1; i <= n; i++)
        if (!indeg[i])
            q.emplace(i);
    while (!q.empty()) {
        int u = q.front();
        q.pop();
        res.emplace_back(u);
        for (int v : adj[u])
            if (--indeg[v] == 0)
                q.emplace(v);
    }
    return res;
}
// CIALLO_END

void B3644() {
    int n;
    cin >> n;
    vector adj(n + 1, vector<int>{});
    for (int u = 1; u <= n; u++) {
        int v;
        while (cin >> v and v)
            adj[u].emplace_back(v);
    }
    auto ans = TopoSort(adj, n);
    for (int i = 0; i < n; i++)
        cout << ans[i] << " \n"[i == n - 1];
}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    B3644();
}
