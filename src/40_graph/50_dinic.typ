#import "../../template.typ": snippet, web-only

== Dinic 最大流
分层图 + 当前弧优化求最大流。

- 默认点编号 `1..n`；
- `AddEdge(u, v, c)` 添加一条容量为 `c` 的有向边，返回边编号；
- `Flow(u, id)` 返回 `u` 的第 `id` 条边的实际流量；
- 一般图复杂度 `O(n^2m)`，二分图等特殊图更快。

#let dinic = ```cpp
struct Dinic {
    struct Edge {
        int to, rev;
        i64 cap;
    };

    int n;
    vector<vector<Edge>> adj;
    vector<int> dep, cur;

    Dinic(int n)
        : n(n), adj(n + 1), dep(n + 1), cur(n + 1) {}

    int AddEdge(int u, int v, i64 c) {
        int id = adj[u].size();
        int revU = adj[v].size();
        int revV = adj[u].size();
        Edge a{v, revU, c};
        Edge b{u, revV, 0};
        adj[u].emplace_back(a);
        adj[v].emplace_back(b);
        return id;
    }

    i64 Flow(int u, int id) const {
        const Edge& e = adj[u][id];
        return adj[e.to][e.rev].cap;
    }

    i64 MaxFlow(int s, int t) {
        i64 flow = 0;
        constexpr i64 INF = numeric_limits<i64>::max() / 4;
        while (bfs(s, t)) {
            fill(cur.begin(), cur.end(), 0);
            while (i64 f = dfs(s, t, INF))
                flow += f;
        }
        return flow;
    }

    bool bfs(int s, int t) {
        fill(dep.begin(), dep.end(), -1);
        queue<int> q;
        dep[s] = 0;
        q.emplace(s);
        while (!q.empty()) {
            int u = q.front();
            q.pop();
            for (auto& e : adj[u]) {
                if (e.cap > 0 and dep[e.to] == -1) {
                    dep[e.to] = dep[u] + 1;
                    q.emplace(e.to);
                }
            }
        }
        return dep[t] != -1;
    }

    i64 dfs(int u, int t, i64 f) {
        if (u == t or f == 0)
            return f;
        for (int& i = cur[u]; i < (i64)adj[u].size(); i++) {
            Edge& e = adj[u][i];
            if (e.cap <= 0 or dep[e.to] != dep[u] + 1)
                continue;
            i64 w = dfs(e.to, t, min(f, e.cap));
            if (!w)
                continue;
            e.cap -= w;
            adj[e.to][e.rev].cap += w;
            return w;
        }
        return 0;
    }
};
```

#snippet(dinic, id: "dinic")
