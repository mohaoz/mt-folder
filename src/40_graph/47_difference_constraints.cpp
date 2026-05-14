#include <bits/stdc++.h>
using namespace std;

// CIALLO_MD
// ## 差分约束
// Bellman-Ford 判负环并求一组可行解。
//
// - 约束形如 `x[v] <= x[u] + w`；
// - `edges` 存储 `(u, v, w)`；
// - 无解返回空数组。
// CIALLO_CODE
auto DifferenceConstraints(
    int n, const vector<array<int, 3>>& edges) {
    vector<long long> d(n + 1);
    for (int i = 1; i <= n; i++) {
        bool changed = false;
        for (auto [u, v, w] : edges) {
            if (d[v] > d[u] + w) {
                d[v] = d[u] + w;
                changed = true;
            }
        }
        if (!changed)
            break;
        if (i == n)
            return vector<long long>{};
    }
    return d;
}
// CIALLO_END

void P5960() {
    int n, m;
    cin >> n >> m;
    vector<array<int, 3>> edges;
    while (m--) {
        int u, v, w;
        cin >> v >> u >> w;
        edges.push_back({u, v, w});
    }
    auto d = DifferenceConstraints(n, edges);
    if (d.empty()) {
        cout << "NO\n";
        return;
    }
    for (int i = 1; i <= n; i++)
        cout << d[i] << " \n"[i == n];
}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    P5960();
}
