#import "../../template.typ": snippet, web-only
// 参考：https://github.com/hh2048/XCPC/tree/main

== 无向图欧拉回路
参考 hh2048/XCPC 的无向图版本，改写为保留边号的非递归
Hierholzer 算法。

- 默认点编号 $1 dots n$，`es[i] = (u, v)`，支持重边与自环；
- 存在奇度点时返回空值，否则返回各连通块回路拼接后的有向边编号：
  `e / 2` 是原边编号，`e & 1` 表示方向与 `(u, v)` 相反；
- CF2192E 中输出所有满足 `e & 1` 的 `e / 2 + 1`；
- 复杂度 $O(n + m)$，空间复杂度 $O(n + m)$。

#let euler-circuit = ```cpp
auto EulerCircuit(
    int n, const vector<pair<int, int>>& es)
    -> optional<vector<int>> {
    int m = es.size();
    vector<vector<int>> adj(n + 1);
    vector<int> deg(n + 1);
    for (int i = 0; i < m; i++) {
        auto [u, v] = es[i];
        adj[u].emplace_back(2 * i);
        adj[v].emplace_back(2 * i + 1);
        deg[u]++, deg[v]++;
    }
    for (int u = 1; u <= n; u++)
        if (deg[u] & 1)
            return nullopt;

    vector<int> tour;
    vector<char> used(m);
    vector<pair<int, int>> stk;
    tour.reserve(m);
    for (int s = 1; s <= n; s++) {
        if (adj[s].empty())
            continue;
        stk = {{s, -1}};
        while (!stk.empty()) {
            int u = stk.back().first;
            while (!adj[u].empty() and
                   used[adj[u].back() / 2])
                adj[u].pop_back();
            if (adj[u].empty()) {
                int e = stk.back().second;
                stk.pop_back();
                if (e != -1)
                    tour.emplace_back(e);
            } else {
                int e = adj[u].back();
                adj[u].pop_back();
                auto [x, y] = es[e / 2];
                int v = e & 1 ? x : y;
                used[e / 2] = true;
                stk.emplace_back(v, e);
            }
        }
    }
    reverse(tour.begin(), tour.end());
    return tour;
}
```

#snippet(euler-circuit, id: "euler-circuit")
