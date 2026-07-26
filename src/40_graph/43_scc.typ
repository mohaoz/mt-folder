#import "../../template.typ": snippet, web-only

== 强连通分量 (SCC)
Tarjan 求有向图强连通分量。

- 默认点编号 `1..n`；
- `id[u]` 为 `u` 所在 SCC 编号；
- 复杂度 `O(n + m)`。

#let scc = ```cpp
struct SCC {
    int n, now = 0, cnt = 0;
    vector<vector<int>> adj;
    vector<int> dfn, low, stk, ins, id;

    SCC(int n)
        : n(n), adj(n + 1), dfn(n + 1), low(n + 1),
          ins(n + 1), id(n + 1) {}

    void AddEdge(int u, int v) {
        adj[u].emplace_back(v);
    }

    void tarjan(int u) {
        dfn[u] = low[u] = ++now;
        stk.emplace_back(u);
        ins[u] = true;
        for (int v : adj[u]) {
            if (!dfn[v]) {
                tarjan(v);
                low[u] = min(low[u], low[v]);
            } else if (ins[v]) {
                low[u] = min(low[u], dfn[v]);
            }
        }
        if (dfn[u] == low[u]) {
            cnt++;
            while (true) {
                int x = stk.back();
                stk.pop_back();
                ins[x] = false;
                id[x] = cnt;
                if (x == u)
                    break;
            }
        }
    }

    std::pair<std::vector<int>, int> Work() {
        for (int i = 1; i <= n; i++)
            if (!dfn[i])
                tarjan(i);
        return {id, cnt};
    }
};
```

#snippet(scc, id: "scc")
