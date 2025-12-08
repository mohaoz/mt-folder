#pragma once

#include <vector>

// ANCHOR: SegTree
template <class S>
struct SegTree {

    int n;
    std::vector<S> tr;

    SegTree(int n, const S &e) {
        build(n, std::vector<S>(n, e));
    }

    SegTree(const std::vector<S> &arr) {
        build(arr.size(), arr);
    }

    void build(int m, const std::vector<S> &arr) {
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

    void Set(int p, S x) {
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
// ANCHOR_END: SegTree
