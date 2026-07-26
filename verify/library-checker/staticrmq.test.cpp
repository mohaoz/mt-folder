// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/staticrmq

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    int n, q;
    std::cin >> n >> q;
    std::vector<int> values(n);
    for (int& value : values)
        std::cin >> value;
    mtf::SparseTable<int> table(
        values,
        [](const int& lhs, const int& rhs) {
            return std::min(lhs, rhs);
        });
    while (q--) {
        int left, right;
        std::cin >> left >> right;
        std::cout << table.Query(left, right) << '\n';
    }
}
