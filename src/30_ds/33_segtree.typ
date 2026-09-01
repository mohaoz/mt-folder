#import "../../template.typ": snippet, web-only

== 线段树

=== 普通线段树
维护单点修改、区间查询。

- 数组下标为 `0..n - 1`；
- `Set(p, x)`、`Get(p)` 操作单点 `p`；
- `Query(l, r)` 查询左闭右开区间 `[l, r)`；
- `SegTree(m, arr)` 使用 `arr[0..m)` 初始化，`arr` 可以是左值或右值。

- 单次操作复杂度 `O(log n)`。

关于 `S` 的约束：

- 存在满足封闭性结合律的 `operator+` 运算；
- 存在单位元 `{}` （具有默认构造函数，且满足和单位元运算后不改变原值）

关于初始序列：

- `arr` 支持随机访问，且至少有 `m` 个元素；
- 若元素类型 ≠ `S`，则必须能赋值给 `S`。

#let segtree = ```cpp
template <class S>
struct SegTree {

    int n;
    std::vector<S> tr;

    SegTree(int m, auto&& arr) {
        for (n = 1; n < m; n <<= 1)
            ;
        tr.resize(n << 1);
        for (int i = 0; i < m; i++)
            tr[i + n] = arr[i];
        for (int i = n - 1; i >= 1; i--)
            pull(i);
    }

    void pull(int k) {
        tr[k] = tr[k << 1] + tr[k << 1 | 1];
    }

    void Set(int p, const S& x) {
        p += n;
        tr[p] = x;
        for (p >>= 1; p; p >>= 1)
            pull(p);
    }

    auto Get(int p) { return tr[p + n]; }

    auto Query(int l, int r) {
        l += n, r += n;
        S sml{}, smr{};
        while (l < r) {
            if (l & 1)
                sml = sml + tr[l++];
            if (r & 1)
                smr = tr[--r] + smr;
            l >>= 1;
            r >>= 1;
        }
        return sml + smr;
    }
};
```

#snippet(segtree, id: "segtree")

`S` 的经典实例——维护最大子段和（Kadane 合并）。
空状态用哨兵 `-1e18` 而 `sum`、`len` 取 0，恰好构成单位元：

```cpp
using i64 = int64_t;

struct Kadane {
    i64 len{};
    i64 sum{}, ans = -1e18;
    i64 pre = -1e18, suf = -1e18;

    Kadane() = default;
    Kadane(i64 v)
        : len(1), sum(v), ans(v), pre(v), suf(v) {}

    friend Kadane operator+(const Kadane& l, const Kadane& r) {
        Kadane res;
        res.len = l.len + r.len;
        res.sum = l.sum + r.sum;
        res.pre = std::max(l.pre, l.sum + r.pre);
        res.suf = std::max(r.suf, l.suf + r.sum);
        res.ans = std::max({l.ans, r.ans, l.suf + r.pre});
        return res;
    }
};
```

=== 动态开点线段树
按需创建访问路径上的节点，适合值域很大而实际修改位置较少的场景。

- `DynSegTree<S>(n)` 维护下标范围 `[0, n)`，要求 `n > 0`；
- `Set(p, x)` 将单点 `p` 赋值为 `x`，`Get(p)` 返回单点值；
- `Query(l, r)` 查询左闭右开区间 `[l, r)`，尚未创建的位置视为 `S{}`；
- `S{}` 必须是 `operator+` 的单位元，`operator+` 必须满足结合律；
- 单次操作复杂度 `O(log n)`；若共有 `q` 个不同位置被修改，空间复杂度
  `O(q log n)`。

#let dynamic-segtree = ```cpp
template <class S>
struct DynSegTree {
    struct Node {
        int ls{}, rs{};
        S val{};
    };

    int n, root{};
    std::vector<Node> tr;

    DynSegTree(int n) : n(n), tr(1) {}

    int newNode() {
        tr.emplace_back();
        return tr.size() - 1;
    }

    auto val(int u) const {
        return u ? tr[u].val : S{};
    }

    void pull(int u) {
        tr[u].val = val(tr[u].ls) + val(tr[u].rs);
    }

    auto set(int u, int l, int r, int p, const S& x) {
        if (!u)
            u = newNode();
        if (r - l == 1) {
            tr[u].val = x;
            return u;
        }
        int mid = l + (r - l) / 2;
        if (p < mid)
            tr[u].ls = set(tr[u].ls, l, mid, p, x);
        else
            tr[u].rs = set(tr[u].rs, mid, r, p, x);
        pull(u);
        return u;
    }

    auto get(int u, int l, int r, int p) const {
        if (!u)
            return S{};
        if (r - l == 1)
            return tr[u].val;
        int mid = l + (r - l) / 2;
        if (p < mid)
            return get(tr[u].ls, l, mid, p);
        return get(tr[u].rs, mid, r, p);
    }

    auto query(int u, int l, int r, int ql, int qr) const {
        if (!u or qr <= l or r <= ql)
            return S{};
        if (ql <= l and r <= qr)
            return tr[u].val;
        int mid = l + (r - l) / 2;
        return query(tr[u].ls, l, mid, ql, qr) +
               query(tr[u].rs, mid, r, ql, qr);
    }

    void Set(int p, const S& x) {
        root = set(root, 0, n, p, x);
    }

    auto Get(int p) const {
        return get(root, 0, n, p);
    }

    auto Query(int l, int r) const {
        return query(root, 0, n, l, r);
    }
};
```

#snippet(dynamic-segtree)
