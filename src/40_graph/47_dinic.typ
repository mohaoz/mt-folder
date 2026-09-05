#import "../../template.typ": snippet, web-only

== Dinic 最大流
分层图 + 当前弧优化求最大流，链式前向星扁平存边。

- 默认点编号 $1 dots n$；
- `AddEdge(u, v, c)` 添加一条容量为 `c` 的有向边，
  返回全局边编号（正反两条成对，`id ^ 1` 即反向边）；
- `Flow(id)` 返回该边的实际流量；
- BFS 在弹出深度不小于 `dep[t]` 的节点时截断：层图到 `t`
  所在层仍然完整，复杂度证明不受影响；
- 一般图复杂度 $O(n^2 m)$，二分图等特殊图更快。

#let dinic = ```cpp
using i64 = int64_t;

struct Dinic {
    int n;
    vector<int> to, nxt, head, dep, cur, que;
    vector<i64> cap;

    Dinic(int n)
        : n(n), head(n + 1, -1), dep(n + 1), cur(n + 1) {}

    int AddEdge(int u, int v, i64 c) {
        int id = to.size();
        to.push_back(v), nxt.push_back(head[u]);
        cap.push_back(c);
        head[u] = id;
        to.push_back(u), nxt.push_back(head[v]);
        cap.push_back(0);
        head[v] = id + 1;
        return id;
    }

    i64 Flow(int id) const { return cap[id ^ 1]; }

    i64 MaxFlow(int s, int t) {
        i64 flow = 0;
        constexpr i64 INF = numeric_limits<i64>::max() / 4;
        while (bfs(s, t)) {
            copy(head.begin(), head.end(), cur.begin());
            while (i64 f = dfs(s, t, INF))
                flow += f;
        }
        return flow;
    }

    bool bfs(int s, int t) {
        fill(dep.begin(), dep.end(), -1);
        que.clear();
        que.push_back(s);
        dep[s] = 0;
        for (size_t i = 0; i < que.size(); i++) {
            int u = que[i];
            if (dep[t] != -1 and dep[u] >= dep[t])
                break;
            for (int e = head[u]; e != -1; e = nxt[e]) {
                if (cap[e] > 0 and dep[to[e]] == -1) {
                    dep[to[e]] = dep[u] + 1;
                    que.push_back(to[e]);
                }
            }
        }
        return dep[t] != -1;
    }

    i64 dfs(int u, int t, i64 f) {
        if (u == t or f == 0)
            return f;
        for (int& e = cur[u]; e != -1; e = nxt[e]) {
            int v = to[e];
            if (cap[e] <= 0 or dep[v] != dep[u] + 1)
                continue;
            i64 w = dfs(v, t, min(f, cap[e]));
            if (w == 0)
                continue;
            cap[e] -= w;
            cap[e ^ 1] += w;
            return w;
        }
        return 0;
    }
};
```

#snippet(dinic, id: "dinic")
