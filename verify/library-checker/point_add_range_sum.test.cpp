// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/point_add_range_sum

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    int n, q;
    std::cin >> n >> q;
    mtf::Fenwick<long long> bit(n);
    for (int i = 1; i <= n; ++i) {
        long long value;
        std::cin >> value;
        bit.Add(i, value);
    }
    while (q--) {
        int type;
        std::cin >> type;
        if (type == 0) {
            int position;
            long long delta;
            std::cin >> position >> delta;
            bit.Add(position + 1, delta);
        } else {
            int left, right;
            std::cin >> left >> right;
            std::cout << bit.Sum(left + 1, right) << '\n';
        }
    }
}
