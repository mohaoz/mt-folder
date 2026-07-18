#import "../../template.typ": snippet, web-only

== ST 表
维护静态区间查询。

- 查询区间为左闭右开 `[l, r)`；
- 运算需要满足结合律和幂等性，例如 `min`、`max`、`gcd`；
- 预处理复杂度 `O(n log n)`，单次查询 `O(1)`。

#let sparse-table = ```cpp
template <class T>
struct SparseTable {
    using Op = std::function<T(const T&, const T&)>;

    int n = 0;
    Op op;
    std::vector<int> lg;
    std::vector<std::vector<T>> st;

    SparseTable() = default;

    SparseTable(const std::vector<T>& a, Op op)
        : op(std::move(op)) {
        Build(a.begin(), a.end());
    }

    template <class It>
    SparseTable(It l, It r, Op op)
        : op(std::move(op)) {
        Build(l, r);
    }

    template <class It>
    void Build(It l, It r) {
        n = int(r - l);
        lg.assign(n + 1, 0);
        for (int i = 2; i <= n; i++)
            lg[i] = lg[i >> 1] + 1;
        st.assign(lg[n] + 1, std::vector<T>(n));
        for (int i = 0; i < n; i++)
            st[0][i] = *(l + i);
        for (int k = 1; k < int(st.size()); k++) {
            int len = 1 << k;
            for (int i = 0; i + len <= n; i++) {
                st[k][i] =
                    op(st[k - 1][i],
                       st[k - 1][i + (len >> 1)]);
            }
        }
    }

    T Query(int l, int r) const {
        assert(0 <= l and l < r and r <= n);
        int k = lg[r - l];
        return op(st[k][l], st[k][r - (1 << k)]);
    }
};
```

#snippet(sparse-table, header: "ds/sparse_table.hpp")
