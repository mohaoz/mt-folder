// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/scc

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    int n, m;
    std::cin >> n >> m;
    mtf::SCC graph(n);
    while (m--) {
        int from, to;
        std::cin >> from >> to;
        graph.AddEdge(from + 1, to + 1);
    }
    auto [component, count] = graph.Work();
    std::vector<std::vector<int>> groups(count + 1);
    for (int vertex = 1; vertex <= n; ++vertex)
        groups[component[vertex]].push_back(vertex - 1);
    std::cout << count << '\n';
    for (int id = count; id >= 1; --id) {
        std::cout << groups[id].size();
        for (int vertex : groups[id])
            std::cout << ' ' << vertex;
        std::cout << '\n';
    }
}
