#import "../../template.typ": snippet, web-only

== Kruskal 重构树
把"按边权阈值连通"转成树上问题：按序加边，每次合并
新建内部节点记录边权，叶子 $1 dots n$ 是原图点。

- 传入的边序自己定：按 `w` 升序建树，两点 LCA 的 `val`
  是路径最大边权的最小值；按降序建树则是
  路径最小边权的最大值（NOIP 货车运输）；
- 内部节点沿根方向 `val` 单调，"与 `u` 在阈值 `w` 内连通的
  点集"是 `u` 某个祖先的整棵子树，可配倍增在祖先链上二分；
- 节点总数至多 $2n - 1$；图不连通时是森林，
  查询前用 `Find` 判连通；
- 两点瓶颈查询：配本章 LCA 模板在重构树上求
  `val[lca(u, v)]`。

#let kruskal-tree = ```cpp
struct KruskalTree {
    int n, tot;
    std::vector<int> f, val;
    std::vector<std::array<int, 2>> son;

    // es 中每条边为 {w, u, v}，按调用方给定的顺序依次合并
    KruskalTree(int n, const std::vector<std::array<int, 3>>& es)
        : n(n), tot(n), f(2 * n), val(2 * n), son(2 * n) {
        std::iota(f.begin(), f.end(), 0);
        for (auto [w, u, v] : es) {
            int x = Find(u), y = Find(v);
            if (x == y)
                continue;
            ++tot;
            val[tot] = w;
            son[tot] = {x, y};
            f[x] = f[y] = tot;
        }
    }

    int Find(int x) {
        while (x != f[x])
            x = f[x] = f[f[x]];
        return x;
    }
};
```

#snippet(kruskal-tree, id: "kruskal-tree")
