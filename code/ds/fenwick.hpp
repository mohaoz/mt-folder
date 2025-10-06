#pragma once

#include <vector>

// ANCHOR: Fenwick
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
// ANCHOR_END: Fenwick
