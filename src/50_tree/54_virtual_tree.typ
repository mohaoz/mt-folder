#import "../../template.typ": snippet, web-only

== 虚树

给定一批关键点，只保留它们、必要的 LCA 与祖先关系，把整棵树压缩成
$O(k)$ 个点。适合多次询问关键点集合上的路径、距离或 DP。

- 依赖本章 `LCA`，会使用 `dfn`、`Get` 与 `IsAncestor`；
- `root` 应是构造 `LCA` 时使用的根，默认是 $1$；
- `nodes` 按 DFS 序排列，`edges` 中每条边为虚树上的 `(parent, child)`；
- 原关键点为空时仍返回根；调用方若要区分关键点与补入的 LCA，需另行标记；
- 设输入关键点数为 $k$，虚树点数为 $O(k)$，构建复杂度
  $O(k log k + k log n)$。

#let virtual-tree = ```cpp
struct VirtualTreeResult {
    vector<int> nodes;
    vector<pair<int, int>> edges;
};

auto BuildVirtualTree(
    vector<int> key, const auto& lca, int root = 1) {
    key.push_back(root);
    auto cmp = [&](int u, int v) {
        return lca.dfn[u] < lca.dfn[v];
    };
    sort(key.begin(), key.end(), cmp);
    key.erase(unique(key.begin(), key.end()), key.end());

    int k = key.size();
    for (int i = 1; i < k; i++)
        key.push_back(lca.Get(key[i - 1], key[i]));
    sort(key.begin(), key.end(), cmp);
    key.erase(unique(key.begin(), key.end()), key.end());

    VirtualTreeResult res;
    vector<int> stk;
    for (int u : key) {
        while (!stk.empty() and
               !lca.IsAncestor(stk.back(), u))
            stk.pop_back();
        if (!stk.empty())
            res.edges.emplace_back(stk.back(), u);
        stk.push_back(u);
    }
    res.nodes = std::move(key);
    return res;
}
```

#snippet(virtual-tree, id: "virtual-tree")
