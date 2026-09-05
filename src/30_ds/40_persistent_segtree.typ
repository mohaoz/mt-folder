#import "../../template.typ": snippet, web-only

== 可持久化权值线段树
主席树：按前缀建版本的权值线段树，两版本相减得到
任意区间的值域信息。

- 值域须先离散化到 $[1, n]$；构造后按原数组顺序逐个 `Add`，
  版本 $i$ 对应前缀 $[1, i]$；
- `Kth(l, r, k)`：下标区间 $[l, r]$（1-indexed）第 $k$ 小的
  离散化值；`Count(l, r, x, y)`：区间内值落在 $[x, y]$ 的个数；
- 单次操作 $O(log n)$；节点数约为 $("插入次数") (log n + 1)$，
  大数据先 `tr.reserve` 防反复扩容；
- 版本 0 是空树（节点 0 自环为空儿子），无需特判。

#let persistent-segtree = ```cpp
struct HJT {
    struct Node {
        int l = 0, r = 0, cnt = 0;
    };

    int n;
    std::vector<Node> tr;
    std::vector<int> root;

    HJT(int n) : n(n), tr(1), root(1, 0) {}

    void Add(int x) {
        root.push_back(add(root.back(), 1, n, x));
    }

    int add(int v, int l, int r, int x) {
        int u = tr.size();
        tr.push_back(tr[v]);
        tr[u].cnt++;
        if (l == r)
            return u;
        int mid = (l + r) / 2;
        if (x <= mid)
            tr[u].l = add(tr[v].l, l, mid, x);
        else
            tr[u].r = add(tr[v].r, mid + 1, r, x);
        return u;
    }

    int Kth(int ql, int qr, int k) {
        return kth(root[ql - 1], root[qr], 1, n, k);
    }

    int kth(int u, int v, int l, int r, int k) {
        if (l == r)
            return l;
        int mid = (l + r) / 2;
        int res = tr[tr[v].l].cnt - tr[tr[u].l].cnt;
        if (k <= res)
            return kth(tr[u].l, tr[v].l, l, mid, k);
        return kth(tr[u].r, tr[v].r, mid + 1, r, k - res);
    }

    int Count(int ql, int qr, int x, int y) {
        return count(root[ql - 1], root[qr], 1, n, x, y);
    }

    int count(int u, int v, int l, int r, int x, int y) {
        if (x <= l and r <= y)
            return tr[v].cnt - tr[u].cnt;
        int mid = (l + r) / 2;
        int res = 0;
        if (x <= mid)
            res += count(tr[u].l, tr[v].l, l, mid, x, y);
        if (y > mid)
            res += count(tr[u].r, tr[v].r, mid + 1, r, x, y);
        return res;
    }
};
```

#snippet(persistent-segtree, id: "persistent-segtree")
