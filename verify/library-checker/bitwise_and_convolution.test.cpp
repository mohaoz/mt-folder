// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/bitwise_and_convolution

#include <mtf_verify.hpp>

using Z = mtf::ModInt<998244353>;

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int n;
    std::cin >> n;
    const int size = 1 << n;
    std::vector<Z> a(size), b(size);
    for (auto& x : a)
        std::cin >> x;
    for (auto& x : b)
        std::cin >> x;

    // AND 卷积：超集和变换域上逐点相乘，再逆变换回来
    mtf::SupersetSum(a);
    mtf::SupersetSum(b);
    for (int i = 0; i < size; ++i)
        a[i] *= b[i];
    mtf::SupersetSum(a, true);

    for (int i = 0; i < size; ++i)
        std::cout << a[i] << " \n"[i == size - 1];
}
