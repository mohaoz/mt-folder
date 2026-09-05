#import "../../template.typ": snippet, web-only

== 最小生成树

以下两份模板使用相同接口：$n >= 1$，无向边 `es[i] = {w, u, v}`，点编号为
$1 dots n$；成功时返回总边权与所选边在 `es` 中的下标，图不连通时返回
`nullopt`。总边权使用 `int64_t`，单条边权使用 `int`。

=== Kruskal

适合直接拿到边表的场景；按边权排序，用并查集依次加入不会成环的边。

- 复杂度 $O(m log m)$；
- 返回的边下标按选入顺序排列。

#let kruskal-mst = ```cpp
auto KruskalMST(
    int n, const vector<array<int, 3>>& es)
    -> optional<pair<int64_t, vector<int>>> {
    vector<int> fa(n + 1), siz(n + 1, 1);
    iota(fa.begin(), fa.end(), 0);
    auto find = [&](auto&& self, int u) -> int {
        if (fa[u] == u)
            return u;
        return fa[u] = self(self, fa[u]);
    };

    vector<int> ord(es.size());
    iota(ord.begin(), ord.end(), 0);
    sort(ord.begin(), ord.end(), [&](int i, int j) {
        return pair{es[i][0], i} < pair{es[j][0], j};
    });

    int64_t cost = 0;
    vector<int> tree;
    tree.reserve(n - 1);
    for (int id : ord) {
        auto [w, u, v] = es[id];
        u = find(find, u);
        v = find(find, v);
        if (u == v)
            continue;
        if (siz[u] < siz[v])
            swap(u, v);
        fa[v] = u;
        siz[u] += siz[v];
        cost += w;
        tree.push_back(id);
    }
    if ((int)tree.size() != n - 1)
        return nullopt;
    return pair<int64_t, vector<int>>{
        cost, std::move(tree)};
}
```

#snippet(kruskal-mst, id: "kruskal-mst")

=== Prim

适合已经围绕点展开、或希望从邻接表思考的场景。模板从点 $1$ 开始，使用
懒删除小根堆，每次选取连接当前生成树与新点的最小边。

- 复杂度 $O((n + m) log m)$，额外空间 $O(n + m)$；
- 允许负边权、重边与自环。

#let prim-mst = ```cpp
auto PrimMST(
    int n, const vector<array<int, 3>>& es)
    -> optional<pair<int64_t, vector<int>>> {
    vector<vector<pair<int, int>>> adj(n + 1);
    for (int id = 0; id < (int)es.size(); id++) {
        auto [w, u, v] = es[id];
        adj[u].emplace_back(v, id);
        adj[v].emplace_back(u, id);
    }

    using State = tuple<int, int, int>;
    priority_queue<State, vector<State>, greater<>> pq;
    vector<bool> vis(n + 1, false);
    vector<int> tree;
    tree.reserve(n - 1);
    int64_t cost = 0;
    int seen = 0;
    pq.emplace(0, 1, -1);
    while (!pq.empty()) {
        auto [w, u, id] = pq.top();
        pq.pop();
        if (vis[u])
            continue;
        vis[u] = true;
        seen++;
        if (id != -1) {
            cost += w;
            tree.push_back(id);
        }
        for (auto [v, eid] : adj[u]) {
            if (!vis[v])
                pq.emplace(es[eid][0], v, eid);
        }
    }
    if (seen != n)
        return nullopt;
    return pair<int64_t, vector<int>>{
        cost, std::move(tree)};
}
```

#snippet(prim-mst, id: "prim-mst")
