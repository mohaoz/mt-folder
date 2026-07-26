// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/bipartitematching

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int left_size, right_size, edge_count;
    std::cin >> left_size >> right_size >> edge_count;

    const int source = 1;
    const int left_base = 2;
    const int right_base = left_base + left_size;
    const int sink = right_base + right_size;
    mtf::Dinic flow(sink);

    for (int left = 0; left < left_size; ++left)
        flow.AddEdge(source, left_base + left, 1);
    for (int right = 0; right < right_size; ++right)
        flow.AddEdge(right_base + right, sink, 1);

    struct Candidate {
        int left, right, from, edge_id;
    };
    std::vector<Candidate> candidates;
    candidates.reserve(edge_count);
    while (edge_count--) {
        int left, right;
        std::cin >> left >> right;
        const int from = left_base + left;
        const int edge_id =
            flow.AddEdge(from, right_base + right, 1);
        candidates.push_back({left, right, from, edge_id});
    }

    std::cout << flow.MaxFlow(source, sink) << '\n';
    for (const auto& edge : candidates) {
        if (flow.Flow(edge.from, edge.edge_id) == 1)
            std::cout << edge.left << ' ' << edge.right << '\n';
    }
}
