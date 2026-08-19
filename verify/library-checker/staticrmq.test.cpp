// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/staticrmq

#include <mtf_verify.hpp>

constexpr auto RangeMin =
    [](const int& lhs, const int& rhs) {
        return std::min(lhs, rhs);
    };

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    int n, q;
    std::cin >> n >> q;
    std::vector<int> values(n);
    for (int& value : values)
        std::cin >> value;
    mtf::SparseTable<int, RangeMin> table(n, values);

    std::vector<int> sample{5, 4, 7, 3, 6};
    mtf::SparseTable<int, RangeMin> sample_table(5, sample);
    auto at_least_four = [](int value) {
        return value >= 4;
    };
    assert(sample_table.MaxRight(0, at_least_four) == 3);
    assert(sample_table.MinLeft(5, at_least_four) == 4);

    while (q--) {
        int left, right;
        std::cin >> left >> right;
        std::cout << table.Query(left, right) << '\n';
    }
}
