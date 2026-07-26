// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/range_kth_smallest

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int n, q;
    std::cin >> n >> q;
    std::vector<int> a(n);
    for (auto& x : a)
        std::cin >> x;

    std::vector<int> values = a;
    std::sort(values.begin(), values.end());
    values.erase(
        std::unique(values.begin(), values.end()),
        values.end());
    const int m = values.size();

    mtf::HJT hjt(m);
    hjt.tr.reserve((n + 1) * 20);
    for (int x : a) {
        const int rank =
            std::lower_bound(values.begin(), values.end(), x) -
            values.begin() + 1;
        hjt.Add(rank);
    }

    while (q--) {
        int l, r, k;
        std::cin >> l >> r >> k;
        std::cout << values[hjt.Kth(l + 1, r, k + 1) - 1] << '\n';
    }
}
