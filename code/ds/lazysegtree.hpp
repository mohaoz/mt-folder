#pragma once

#include <vector>
#include <bit>

// ANCHOR: LazySegTree
template<class S, class F>
struct LazySegTree {

    int n, h;
    std::vector<S> tr;
    std::vector<F> lz;

     LazySegTree(int m, auto &&arr) {
        n = std::bit_ceil((size_t)m);
        h = std::countr_zero((size_t)n);
        tr.resize(2 * n);
        lz.resize(n);
        for (int i = 0; i < n; i++)
            tr[n + i] = arr[i];
        for (int i = n - 1; i >= 1; i--)
            pull(i);
    }

    void apply(int k, const F &f) {
        tr[k] *= f;
        if (k < n)
            lz[k] += f;
    }

#define updown(x) do {                         \
    if (((l >> i) << i) != l) x(l >> i);       \
    if (((r >> i) << i) != r) x((r - 1) >> i); \
} while(0)

    void pull(int k) {
        tr[k] = tr[k << 1] + tr[k << 1 | 1];
    }

    void push(int k) {
        apply(k << 1, lz[k]);
        apply(k << 1 | 1, lz[k]);
        lz[k] = {};
    }

    void Set(int p, S x) {
        p += n;
        for (int i = h; i >= 1; i--) push(p >> i);
        tr[p] = x;
        for (int i = 1; i <= h; i++) pull(p >> i);
    }

    S Get(int p) {
        p += n;
        for (int i = h; i >= 1; i--) push(p >> i);
        return tr[p];
    }

    void Update(int l, int r, const F &f) {
        l += n, r += n;
        for (int i = h; i >= 1; i--) {
            updown(push);
        }
        {
            int l_ = l, r_ = r;
            while (l < r) {
                if (l & 1) apply(l++, f);
                if (r & 1) apply(--r, f);
                l >>= 1;
                r >>= 1;
            }
            l = l_;
            r = r_;
        }
        for (int i = 1; i <= h; i++) {
            updown(pull);
        }
    }

    S Query(int l, int r) {
        l += n, r += n;
        for (int i = h; i >= 1; i--) {
            updown(push);
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
// ANCHOR_END: LazySegTree
