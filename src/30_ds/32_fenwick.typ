#import "../../template.typ": snippet, web-only

== 树状数组
维护单点加、前缀和、区间和。

- 使用 `1-indexed`；
- `Sum(l, r)` 查询闭区间 $[l, r]$；
- 单次操作复杂度 $O(log n)$。

#let fenwick = ```cpp
template <typename T>
struct Fenwick {
    int n;
    std::vector<T> a;

    Fenwick(int n) : n(n), a(n + 1) {}

    void Add(int x, T v) {
        for (int i = x; i <= n; i += i & -i)
            a[i] += v;
    }

    auto sum(int x) {
        T res = {};
        for (int i = x; i; i -= i & -i)
            res += a[i];
        return res;
    }

    auto Sum(int l, int r) {
        return sum(r) - sum(l - 1);
    }
};
```

#snippet(fenwick, id: "fenwick")
