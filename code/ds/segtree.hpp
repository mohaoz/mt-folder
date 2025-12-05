#pragma once

#include <vector>

// ANCHOR: SegTree
template<class S>
struct SegTree {

    int n, h;
    std::vector<S> tr;

     SegTree(int m, auto &&arr) {
        n = std::bit_ceil((size_t)m);
        h = std::countr_zero((size_t)n);
        tr.resize(2 * n);
        for (int i = 0; i < n; i++)
            tr[n + i] = arr[i];
        for (int i = n - 1; i >= 1; i--)
            pull(i);
    }

    void pull(int k) {
        tr[k] = tr[k << 1] + tr[k << 1 | 1];
    }

    void Set(int p, S x) {
        p += n;
        tr[p] = x;
        for (int i = 1; i <= h; i++)
            pull(p >> i);
    }

    S Get(int p) {
        return tr[p + n];
    }

    S Query(int l, int r) {
        l += n, r += n;
        S res{};
        while (l < r) {
            if (l & 1)
                res = res + tr[l++];
            if (r & 1)
                res = res + tr[--r];
            l >>= 1;
            r >>= 1;
        }
        return res;
    }
};
// ANCHOR_END: SegTree
