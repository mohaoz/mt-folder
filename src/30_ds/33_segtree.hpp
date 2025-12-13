#pragma once

#include <vector>

// CIALLO_MD
// ## 线段树
// 关于 `S` 的约束：
// 
// - 存在满足封闭性结合律的 `operator+` 运算；
// - 存在单位元 `{}` （具有默认构造函数，且满足和单位元运算后不改变原值）
// 
// 关于初始数组 `vector<T>`：
// 
// - 若 `T` $\neq$ `S`，则必须保证 `S` 存在可由 `T` 构造的构造函数。
// 
// CIALLO_CODE
template <class S>
struct SegTree {

    int n;
    std::vector<S> tr;

    SegTree(int n, const S &e) {
        build(n, std::vector<S>(n, e));
    }

    SegTree(auto &&l, auto &&r) {
        build(r - l, l);
    }

    void build(int m, auto &&arr) {
        for (n = 1; n < m; n <<= 1);
        tr.resize(n << 1);
        for (int i = 0; i < m; i++)
            tr[i + n] = arr[i];
        for (int i = n - 1; i >= 1; i--)
            pull(i);
    }

    void pull(int k) {
        tr[k] = tr[k << 1] + tr[k << 1 | 1];
    }

    void Set(int p, const S &x) {
        p += n;
        tr[p] = x;
        for (p >>= 1; p; p >>= 1)
            pull(p);
    }

    S Get(int p) {
        return tr[p + n];
    }

    S Query(int l, int r) {
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
// CIALLO_END
