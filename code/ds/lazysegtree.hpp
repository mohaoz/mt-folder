#pragma once

#include <vector>

// ANCHOR: LazySegTree
template <class S, class F> struct LazySegTree {
    int n;
    std::vector<S> tree;
    std::vector<F> tag;

    void apply(int p, F f) {
        tree[p] *= f;
        tag[p] += f;
    }

    void build(auto &&v, int p, int l, int r) {
        if (l == r) {
            tree[p] = S(v[l]);
            return;
        }
        int mid = l + (r - l) / 2;
        build(v, 2 * p, l, mid);
        build(v, 2 * p + 1, mid + 1, r);
        pull(p);
    }

    void pull(int p) { tree[p] = tree[2 * p] + tree[2 * p + 1]; }

    void push(int p) {
        apply(2 * p, tag[p]);
        apply(2 * p + 1, tag[p]);
        tag[p] = F{};
    }

    S query(int ql, int qr, int p, int l, int r) {
        if (r < ql or qr < l)
            return S{};
        if (ql <= l and r <= qr)
            return tree[p];
        push(p);
        int mid = l + (r - l) / 2;
        return query(ql, qr, 2 * p, l, mid) + query(ql, qr, 2 * p + 1, mid + 1, r);
    }

    void update(int ul, int ur, F f, int p, int l, int r) {
        if (r < ul or ur < l)
            return;
        if (ul <= l and r <= ur) {
            apply(p, f);
            return;
        }
        push(p);
        int mid = l + (r - l) / 2;
        update(ul, ur, f, 2 * p, l, mid);
        update(ul, ur, f, 2 * p + 1, mid + 1, r);
        pull(p);
    }

    LazySegTree(int n) : n(n), tree(4 * n), tag(4 * n) {}
    LazySegTree(auto &&v) : n(v.size()), tree(4 * n), tag(4 * n) {
        build(v, 1, 0, n - 1);
    }

    S Query(int l, int r) { return query(l, r, 1, 0, n - 1); }
    void Update(int l, int r, F f) { update(l, r, f, 1, 0, n - 1); }
};
// ANCHOR_END: LazySegTree
