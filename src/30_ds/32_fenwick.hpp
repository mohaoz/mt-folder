#pragma once

#include <vector>

// CIALLO_MD
// ## 树状数组
// 维护单点加、前缀和、区间和。
//
// - 使用 `1-indexed`；
// - `Sum(l, r)` 查询闭区间 `[l, r]`；
// - 单次操作复杂度 `O(log n)`。
// CIALLO_CODE
template <typename T> struct Fenwick {
    int n;
    std::vector<T> a;

    Fenwick(int n) : n(n), a(n + 1) {}

    void Add(int x, T v) {
        for (; x <= n; x += x & -x)
            a[x] += v;
    }

    T sum(int x) {
        T res = {};
        for (; x; x -= x & -x)
            res += a[x];
        return res;
    }

    T Sum(int l, int r) { return sum(r) - sum(l - 1); }
};
// CIALLO_END
