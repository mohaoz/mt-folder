#pragma once

#include <numeric>
#include <vector>

// CIALLO_MD
// ## 并查集 (DSU)
// CIALLO_CODE
struct DSU {
    std::vector<int> f;

    DSU(int n) : f(n) { std::iota(f.begin(), f.end(), 0); }

    int Find(int x) {
        while (x != f[x])
            x = f[x] = f[f[x]];
        return x;
    }

    bool Merge(int x, int y) {
        x = Find(x), y = Find(y);
        if (x == y)
            return false;
        f[y] = x;
        return true;
    }
};
// CIALLO_END
