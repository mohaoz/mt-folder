// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/convolution_mod

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int n, m;
    std::cin >> n >> m;
    std::vector<int64_t> a(n), b(m);
    for (auto &x : a)
        std::cin >> x;
    for (auto &x : b)
        std::cin >> x;

    auto c = mtf::NTT<998244353>::Convolution(a, b);
    for (int i = 0; i < static_cast<int>(c.size()); i++)
        std::cout << c[i] << " \n"[i + 1 == static_cast<int>(c.size())];
}
