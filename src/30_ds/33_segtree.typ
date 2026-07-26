#import "../../template.typ": snippet, web-only

== 线段树
维护单点修改、区间查询。

- 单次操作复杂度 `O(log n)`。

关于 `S` 的约束：

- 存在满足封闭性结合律的 `operator+` 运算；
- 存在单位元 `{}` （具有默认构造函数，且满足和单位元运算后不改变原值）

关于初始区间：

- 使用随机访问迭代器；
- 若元素类型 ≠ `S`，则必须保证 `S` 存在对应构造函数。

#let segtree = ```cpp
template <class S>
struct SegTree {

    int n;
    std::vector<S> tr;

    SegTree(int n, const S& e) {
        build(n, std::vector<S>(n, e));
    }

    template <class It>
    SegTree(It l, It r) {
        build(r - l, l);
    }

    template <class Arr>
    void build(int m, const Arr& arr) {
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
