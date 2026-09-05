#import "../../template.typ": snippet, web-only

== 势能线段树
处理不满足结合律、但会让元素快速收敛的区间修改
（区间开方、区间取模等）：额外维护区间最大值，
整段已收敛则直接跳过。

- 模板实现区间开方 + 区间求和（洛谷 P4145）：
  $"mx" <= 1$ 的子树开方不变，整棵剪掉；
- 每个元素开方 $O(log log V)$ 次后收敛到 $1$，
  总复杂度 $O((n + q log n) log log V)$ 量级；
- 区间取模变体：改判 $"mx" < x$ 则跳过，叶子执行 `a_i %= x`
  （每次有效取模至少减半，势能同理）；
- 修改必须递归到叶子逐个执行，不能打懒标记——
  剪枝条件是正确性的全部来源。

#let potential-segtree = ```cpp
using i64 = int64_t;

struct PotSegTree {
    struct Node {
        i64 sum = 0, mx = 0;
    };

    int n;
    std::vector<Node> tr;

    PotSegTree(auto first, auto last)
        : n(last - first), tr(4 * n) {
        build(first, 1, 0, n - 1);
    }

    void build(auto a, int p, int l, int r) {
        if (l == r) {
            tr[p] = {a[l], a[l]};
            return;
        }
        int mid = (l + r) / 2;
        build(a, 2 * p, l, mid);
        build(a, 2 * p + 1, mid + 1, r);
        pull(p);
    }

    void pull(int p) {
        tr[p].sum = tr[2 * p].sum + tr[2 * p + 1].sum;
        tr[p].mx = std::max(tr[2 * p].mx, tr[2 * p + 1].mx);
    }

    void Sqrt(int l, int r) { sqrt(l, r, 1, 0, n - 1); }

    void sqrt(int ql, int qr, int p, int l, int r) {
        if (qr < l or r < ql or tr[p].mx <= 1)
            return;
        if (l == r) {
            tr[p].sum = tr[p].mx = i64(sqrtl(tr[p].sum));
            return;
        }
        int mid = (l + r) / 2;
        sqrt(ql, qr, 2 * p, l, mid);
        sqrt(ql, qr, 2 * p + 1, mid + 1, r);
        pull(p);
    }

    i64 Query(int l, int r) {
        return query(l, r, 1, 0, n - 1);
    }

    i64 query(int ql, int qr, int p, int l, int r) {
        if (qr < l or r < ql)
            return 0;
        if (ql <= l and r <= qr)
            return tr[p].sum;
        int mid = (l + r) / 2;
        return query(ql, qr, 2 * p, l, mid) +
               query(ql, qr, 2 * p + 1, mid + 1, r);
    }
};
```

#snippet(potential-segtree, id: "potential-segtree")
