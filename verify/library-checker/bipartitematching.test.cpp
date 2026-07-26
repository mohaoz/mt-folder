// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/bipartitematching

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    int left_size, right_size, edge_count;
    std::cin >> left_size >> right_size >> edge_count;
    mtf::HopcroftKarp matching(left_size, right_size);
    while (edge_count--) {
        int left, right;
        std::cin >> left >> right;
        matching.AddEdge(left + 1, right + 1);
    }
    std::cout << matching.Work() << '\n';
    for (int left = 1; left <= left_size; ++left) {
        if (matching.matchL[left] != 0)
            std::cout << left - 1 << ' '
                      << matching.matchL[left] - 1 << '\n';
    }
}
