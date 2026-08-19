#import "../../template.typ": snippet, web-only

== ST 表
维护静态区间查询。

- 查询区间为左闭右开 `[l, r)`；
- `SparseTable(m, arr)` 使用 `arr[0..m)` 初始化，`arr` 可以是左值或右值；
- `MaxRight(l, f)` 返回最大的 `r in [l, n]`，使得 `r == l` 或 `f(Query(l, r))`；
- `MinLeft(r, f)` 返回最小的 `l in [0, r]`，使得 `l == r` 或 `f(Query(l, r))`；
- 预处理复杂度 `O(n log n)`，单次查询 `O(1)`，单次二分 `O(log n)`。

关于 `Op` 的约束：

- `Op(a, b)` 返回一个 `T`；
- 运算满足封闭性、结合律和幂等性，例如 `min`、`max`、`gcd`。

关于初始序列：

- `arr` 支持随机访问，且至少有 `m` 个元素；
- 若元素类型 ≠ `T`，则必须能赋值给 `T`。

关于二分谓词 `f` 的约束：

- `f` 接受一个 `T` 并返回 `bool`，且没有副作用；
- 从固定端点向外扩展区间时，`f` 的结果至多从 `true` 变为 `false` 一次；
- 空区间视为满足谓词，但不会调用 `f`，因此返回值可以等于固定端点。

#let sparse-table = ```cpp
template <class T, auto Op>
struct SparseTable {
    int n;
    std::vector<int> lg;
    std::vector<std::vector<T>> st;

    SparseTable(int m, auto&& arr) : n(m) {
        lg.assign(n + 1, 0);
        for (int i = 2; i <= n; i++)
            lg[i] = lg[i >> 1] + 1;
        st.assign(lg[n] + 1, std::vector<T>(n));
        for (int i = 0; i < n; i++)
            st[0][i] = arr[i];
        for (int k = 1; k < static_cast<int>(st.size()); k++) {
            int len = 1 << k;
            for (int i = 0; i + len <= n; i++) {
                st[k][i] =
                    Op(st[k - 1][i],
                       st[k - 1][i + (len >> 1)]);
            }
        }
    }

    T Query(int l, int r) const {
        assert(0 <= l and l < r and r <= n);
        int k = lg[r - l];
        return Op(st[k][l], st[k][r - (1 << k)]);
    }

    int MaxRight(int l, auto f) const {
        assert(0 <= l and l <= n);
        int low = l, high = n;
        while (low < high) {
            int mid = low + (high - low + 1) / 2;
            if (f(Query(l, mid)))
                low = mid;
            else
                high = mid - 1;
        }
        return low;
    }

    int MinLeft(int r, auto f) const {
        assert(0 <= r and r <= n);
        int low = 0, high = r;
        while (low < high) {
            int mid = low + (high - low) / 2;
            if (f(Query(mid, r)))
                high = mid;
            else
                low = mid + 1;
        }
        return low;
    }
};
```

#snippet(sparse-table, id: "sparse-table")

本实现默认使用 C++20。`Op` 可直接传入无捕获 lambda，例如
`SparseTable<int, [](int a, int b) { return std::min(a, b); }> st(n, arr)`。

C++17 下：

- 在构造函数前添加 `template <class A>`，并把形参 `auto&& arr` 换成 `A&& arr`；
- 在 `MaxRight`、`MinLeft` 前各添加 `template <class F>`，并把形参 `auto f` 换成 `F f`；
- 将 `Op` 的 lambda 换成普通函数 `int Min(int a, int b)`，再使用
  `SparseTable<int, Min> st(n, arr)`。
