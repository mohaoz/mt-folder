#pragma once

#include <vector>

// ANCHOR: SegTree
template <class S> struct SegTree {
    int n;
    std::vector<S> tree;

    void pull(int p) { tree[p] = tree[2 * p] + tree[2 * p + 1]; }

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

    S query(int ql, int qr, int p, int l, int r) {
        if (ql > r or qr < l)
            return {};
        if (ql <= l and r <= qr)
            return tree[p];
        int mid = l + (r - l) / 2;
        return query(ql, qr, 2 * p, l, mid) + query(ql, qr, 2 * p + 1, mid + 1, r);
    }

    void update(int pos, const S &val, int p, int l, int r) {
        if (l == r) {
            tree[p] = val;
            return;
        }
        int mid = l + (r - l) / 2;
        if (pos <= mid)
            update(pos, val, 2 * p, l, mid);
        else
            update(pos, val, 2 * p + 1, mid + 1, r);
        pull(p);
    }

    SegTree() : n(0) {}
    SegTree(int _n) : n(_n), tree(4 * n, {}) {}
    SegTree(auto &&v) : n(v.size()) {
        tree.resize(4 * n);
        build(v, 1, 0, n - 1);
    }

    S Query(int l, int r) { return query(l, r, 1, 0, n - 1); }

    void Update(int p, const S &v) { update(p, v, 1, 0, n - 1); }
};
// ANCHOR_END: SegTree
