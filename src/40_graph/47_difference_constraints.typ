#import "../../template.typ": snippet, web-only

== 差分约束
Bellman-Ford 判负环并求一组可行解。

- 约束形如 `x[v] <= x[u] + w`；
- `edges` 存储 `(u, v, w)`；
- 无解返回空数组。

#let difference-constraints = ```cpp
auto DifferenceConstraints(
    int n, const vector<array<int, 3>>& edges) {
    vector<i64> d(n + 1);
    for (int i = 1; i <= n; i++) {
        bool changed = false;
        for (auto [u, v, w] : edges) {
            if (d[v] > d[u] + w) {
                d[v] = d[u] + w;
                changed = true;
            }
        }
        if (!changed)
            break;
        if (i == n)
            return vector<i64>{};
    }
    return d;
}
```

#snippet(difference-constraints, header: "graph/difference_constraints.hpp")
