#import "../../template.typ": snippet, web-only

== 懒标记线段树
使用非递归的实现方式。

- 数组下标为 `0..n - 1`；
- `Set(p, x)`、`Get(p)` 操作单点 `p`；
- `Update(l, r, f)`、`Query(l, r)` 操作左闭右开区间 `[l, r)`；
- `LazySegTree(m, arr)` 使用 `arr[0..m)` 初始化，`arr` 可以是左值或右值。

- 单次操作复杂度 `O(log n)`。

关于 `F` 的约束：

- 存在满足封闭性的 `operator+=` 运算；
- 存在一个恒等映射 `{}`（默认构造函数）。

关于 `S` 的约束：

- 存在满足封闭性结合律的 `operator+` 运算；
- 存在单位元 `{}` （具有默认构造函数，且满足和单位元运算后不改变原值）
- 存在 `operator*=` 运算满足将映射 `F` 应用于 `S` 返回一个 `S`，并且满足分配律。

关于初始序列：

- `arr` 支持随机访问，且至少有 `m` 个元素；
- 若元素类型 ≠ `S`，则必须能赋值给 `S`。

#let lzseg = ```cpp
template <class S, class F>
struct LazySegTree {

    int n, h;
    std::vector<S> tr;
    std::vector<F> lz;

    LazySegTree(int m, auto&& arr) {
        for (n = 1; n < m; n <<= 1)
            ;
        h = std::countr_zero((unsigned)n);
        tr.resize(n << 1);
        lz.resize(n);
        for (int i = 0; i < m; i++)
            tr[i + n] = arr[i];
        for (int i = n - 1; i >= 1; i--)
            pull(i);
    }

    void apply(int k, const F& f) {
        tr[k] *= f;
        if (k < n)
            lz[k] += f;
    }

    void pull(int k) {
        tr[k] = tr[k << 1] + tr[k << 1 | 1];
    }

    void push(int k) {
        apply(k << 1, lz[k]);
        apply(k << 1 | 1, lz[k]);
        lz[k] = {};
    }

    void Set(int p, const S& x) {
        p += n;
        for (int i = h; i >= 1; i--)
            push(p >> i);
        tr[p] = x;
        for (int i = 1; i <= h; i++)
            pull(p >> i);
    }

    auto Get(int p) {
        p += n;
        for (int i = h; i >= 1; i--)
            push(p >> i);
        return tr[p];
    }

    void Update(int l, int r, const F& f) {
        l += n, r += n;
        for (int i = h; i >= 1; i--) {
            if ((l & ((1 << i) - 1)) != 0)
                push(l >> i);
            if ((r & ((1 << i) - 1)) != 0)
                push((r - 1) >> i);
        }
        {
            int l_ = l, r_ = r;
            while (l < r) {
                if (l & 1)
                    apply(l++, f);
                if (r & 1)
                    apply(--r, f);
                l >>= 1;
                r >>= 1;
            }
            l = l_;
            r = r_;
        }
        for (int i = 1; i <= h; i++) {
            if ((l & ((1 << i) - 1)) != 0)
                pull(l >> i);
            if ((r & ((1 << i) - 1)) != 0)
                pull((r - 1) >> i);
        }
    }

    auto Query(int l, int r) {
        l += n, r += n;
        for (int i = h; i >= 1; i--) {
            if ((l & ((1 << i) - 1)) != 0)
                push(l >> i);
            if ((r & ((1 << i) - 1)) != 0)
                push((r - 1) >> i);
        }
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

#snippet(lzseg, id: "lzseg")
