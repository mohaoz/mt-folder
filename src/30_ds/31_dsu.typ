#import "../../template.typ": snippet, web-only

= 数据结构
== 并查集 (DSU)
维护无向连通性和连通块大小，`Merge(x, y)` 返回是否真的合并成功。

#let dsu = ```cpp
struct DSU {
    std::vector<int> f, sz;

    DSU(int n) : f(n), sz(n, 1) {
        std::iota(f.begin(), f.end(), 0);
    }

    auto Find(int x) {
        while (x != f[x])
            x = f[x] = f[f[x]];
        return x;
    }

    auto Merge(int x, int y) {
        x = Find(x), y = Find(y);
        if (x == y)
            return false;
        if (sz[x] < sz[y])
            std::swap(x, y);
        sz[x] += sz[y];
        f[y] = x;
        return true;
    }

    auto Size(int x) { return sz[Find(x)]; }
};
```

#snippet(dsu, header: "ds/dsu.hpp")
