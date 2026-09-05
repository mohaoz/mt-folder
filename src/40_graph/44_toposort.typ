#import "../../template.typ": snippet, web-only

== 拓扑排序
Kahn 算法。

- 默认点编号 $1 dots n$；
- 若返回数量小于 $n$，则图中有环；
- 复杂度 $O(n + m)$。

#let toposort = ```cpp
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
```

#snippet(toposort)
