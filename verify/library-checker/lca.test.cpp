// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/lca

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    int n, q;
    std::cin >> n >> q;
    std::vector<std::vector<int>> tree(n + 1);
    for (int vertex = 1; vertex < n; ++vertex) {
        int parent;
        std::cin >> parent;
        ++parent;
        const int child = vertex + 1;
        tree[parent].push_back(child);
        tree[child].push_back(parent);
    }
    mtf::LCA lca(tree);
    while (q--) {
        int u, v;
        std::cin >> u >> v;
        std::cout << lca.Get(u + 1, v + 1) - 1 << '\n';
    }
}
