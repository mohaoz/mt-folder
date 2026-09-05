#import "../../template.typ": snippet, web-only

== DSU on Tree

又称 Sack、树上启发式合并。先处理轻儿子并清空贡献，再保留重儿子的贡献，
从而让每个点被重复加入的次数至多为 $O(log n)$。

- `add(u)` 把点 $u$ 加入当前状态，`remove(u)` 必须执行严格相反的操作；
- 调用 `answer(u)` 时，当前状态恰好包含 $u$ 的整棵子树；
- 调用前后状态均为空；`adj` 是点编号 $1 dots n$ 的无向树；
- 若三个回调均为 $O(1)$，总复杂度为 $O(n log n)$，额外空间为 $O(n)$；
- 实现使用递归，链状树上需要留意系统栈深度。

#let dsu-on-tree = ```cpp
void DsuOnTree(
    const vector<vector<int>>& adj, int root,
    auto&& add, auto&& remove, auto&& answer) {
    int n = adj.size() - 1;
    vector<int> siz(n + 1, 1), heavy(n + 1, 0);

    auto init = [&](auto&& self, int u,
                    int p) -> void {
        for (int v : adj[u]) {
            if (v == p)
                continue;
            self(self, v, u);
            siz[u] += siz[v];
            if (!heavy[u] or siz[v] > siz[heavy[u]])
                heavy[u] = v;
        }
    };
    init(init, root, 0);

    auto modify = [&](auto&& self, int u, int p,
                      bool insert) -> void {
        if (insert)
            add(u);
        else
            remove(u);
        for (int v : adj[u]) {
            if (v != p)
                self(self, v, u, insert);
        }
    };

    auto dfs = [&](auto&& self, int u, int p,
                   bool keep) -> void {
        for (int v : adj[u]) {
            if (v != p and v != heavy[u])
                self(self, v, u, false);
        }
        if (heavy[u])
            self(self, heavy[u], u, true);
        for (int v : adj[u]) {
            if (v != p and v != heavy[u])
                modify(modify, v, u, true);
        }
        add(u);
        answer(u);
        if (!keep)
            modify(modify, u, p, false);
    };
    dfs(dfs, root, 0, false);
}
```

#snippet(dsu-on-tree, id: "dsu-on-tree")

例如统计每棵子树的颜色数时，只需维护 `cnt[color[u]]` 与当前不同颜色数，
在 `answer(u)` 中记录答案；模板本身无需知道具体维护量。
