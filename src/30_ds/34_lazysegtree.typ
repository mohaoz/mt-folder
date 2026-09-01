#import "../../template.typ": snippet, web-only

== 懒标记线段树

=== 普通懒标记线段树
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

`S` 和 `F` 的经典实例——#link("https://www.luogu.com.cn/problem/P1253")[
P1253 扶苏的问题]：区间赋值、区间加法、区间最大值查询。

`Info{}` 以负无穷为单位元；`Tag{}` 是恒等映射。`Tag::operator+=` 表示先执行
当前标记、再执行 `rhs`，因此 `rhs` 中的赋值会覆盖已有标记，而加法会继续累加：

```cpp
using i64 = int64_t;

struct Tag {
    i64 assign{}, add{};
    bool has_assign{};

    static Tag Assign(i64 x) {
        Tag f;
        f.assign = x;
        f.has_assign = true;
        return f;
    }

    static Tag Add(i64 x) {
        Tag f;
        f.add = x;
        return f;
    }

    Tag& operator+=(const Tag& rhs) {
        if (rhs.has_assign) {
            assign = rhs.assign;
            add = rhs.add;
            has_assign = true;
        } else {
            add += rhs.add;
        }
        return *this;
    }
};

struct Info {
    static constexpr i64 NEG_INF =
        std::numeric_limits<i64>::lowest() / 4;
    i64 mx;

    Info(i64 mx = NEG_INF) : mx(mx) {}

    friend Info operator+(const Info& lhs, const Info& rhs) {
        return Info(std::max(lhs.mx, rhs.mx));
    }

    Info& operator*=(const Tag& f) {
        if (mx == NEG_INF)
            return *this;
        if (f.has_assign)
            mx = f.assign;
        mx += f.add;
        return *this;
    }
};

std::vector<i64> a(n);
LazySegTree<Info, Tag> seg(n, a);

// 题目区间 [l, r] 对应模板的 [l - 1, r)。
seg.Update(l - 1, r, Tag::Assign(x));  // op = 1
seg.Update(l - 1, r, Tag::Add(x));     // op = 2
i64 answer = seg.Query(l - 1, r).mx;   // op = 3
```

=== 动态开点懒标记线段树
按需创建节点，同时支持单点赋值、区间修改和区间查询。

- `DynLazySegTree<S, F>(n)` 维护下标范围 `[0, n)`，要求 `n > 0`；
- `Set(p, x)`、`Get(p)` 操作单点，`Update(l, r, f)`、`Query(l, r)` 操作
  左闭右开区间 `[l, r)`；
- `S::Init(l, r)` 返回未修改区间 `[l, r)` 的初始聚合值，并满足按任意
  中点拆分后仍可用 `operator+` 合并；
- `S{}` 是查询结果的单位元，`S *= F` 应用映射；`F{}` 是恒等映射，
  `tag += f` 表示在已有标记之后追加 `f`；
- `Get` 和 `Query` 会下推懒标记，可能创建新节点，因此不是 `const` 操作；
- 单次操作复杂度 `O(log n)`；执行 `q` 次操作后的空间复杂度上界为
  `O(q log n)`。

#let dynamic-lazy-segtree = ```cpp
template <class S, class F>
struct DynLazySegTree {
    struct Node {
        int ls{}, rs{};
        S val{};
        F tag{};
        bool has{};
    };

    int n, root{};
    std::vector<Node> tr;

    DynLazySegTree(int n) : n(n), tr(1) {}

    int newNode(int l, int r) {
        tr.emplace_back();
        int u = tr.size() - 1;
        tr[u].val = S::Init(l, r);
        return u;
    }

    auto val(int u, int l, int r) const {
        return u ? tr[u].val : S::Init(l, r);
    }

    void apply(int u, const F& f) {
        tr[u].val *= f;
        tr[u].tag += f;
        tr[u].has = true;
    }

    void pull(int u, int l, int r) {
        int mid = l + (r - l) / 2;
        tr[u].val =
            val(tr[u].ls, l, mid) +
            val(tr[u].rs, mid, r);
    }

    void push(int u, int l, int r) {
        if (!tr[u].has or r - l == 1)
            return;

        int mid = l + (r - l) / 2;
        int ls = tr[u].ls;
        int rs = tr[u].rs;
        F f = tr[u].tag;

        if (!ls)
            ls = newNode(l, mid);
        if (!rs)
            rs = newNode(mid, r);

        tr[u].ls = ls;
        tr[u].rs = rs;
        tr[u].tag = {};
        tr[u].has = false;

        apply(ls, f);
        apply(rs, f);
    }

    auto set(int u, int l, int r, int p, const S& x) {
        if (!u)
            u = newNode(l, r);

        if (r - l == 1) {
            tr[u].val = x;
            tr[u].tag = {};
            tr[u].has = false;
            return u;
        }

        push(u, l, r);

        int mid = l + (r - l) / 2;
        if (p < mid)
            tr[u].ls = set(tr[u].ls, l, mid, p, x);
        else
            tr[u].rs = set(tr[u].rs, mid, r, p, x);

        pull(u, l, r);
        return u;
    }

    auto get(int u, int l, int r, int p) {
        if (!u)
            return S::Init(p, p + 1);

        if (r - l == 1)
            return tr[u].val;

        push(u, l, r);

        int mid = l + (r - l) / 2;
        if (p < mid)
            return get(tr[u].ls, l, mid, p);
        return get(tr[u].rs, mid, r, p);
    }

    auto update(int u, int l, int r,
                int ql, int qr, const F& f) {
        if (qr <= l or r <= ql)
            return u;

        if (!u)
            u = newNode(l, r);

        if (ql <= l and r <= qr) {
            apply(u, f);
            return u;
        }

        push(u, l, r);

        int mid = l + (r - l) / 2;
        tr[u].ls =
            update(tr[u].ls, l, mid, ql, qr, f);
        tr[u].rs =
            update(tr[u].rs, mid, r, ql, qr, f);

        pull(u, l, r);
        return u;
    }

    auto query(int u, int l, int r,
               int ql, int qr) {
        if (qr <= l or r <= ql)
            return S{};

        if (!u)
            return S::Init(
                std::max(l, ql),
                std::min(r, qr)
            );

        if (ql <= l and r <= qr)
            return tr[u].val;

        push(u, l, r);

        int mid = l + (r - l) / 2;
        return query(tr[u].ls, l, mid, ql, qr) +
               query(tr[u].rs, mid, r, ql, qr);
    }

    void Set(int p, const S& x) {
        root = set(root, 0, n, p, x);
    }

    auto Get(int p) {
        return get(root, 0, n, p);
    }

    void Update(int l, int r, const F& f) {
        root = update(root, 0, n, l, r, f);
    }

    auto Query(int l, int r) {
        return query(root, 0, n, l, r);
    }
};
```

#snippet(dynamic-lazy-segtree)
