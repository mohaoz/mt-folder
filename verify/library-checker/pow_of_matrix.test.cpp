// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/pow_of_matrix

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int n;
    mtf::i64 k;
    std::cin >> n >> k;
    mtf::MatrixOps::n = n;
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            std::cin >> mtf::MatrixOps::a[i][j];

    mtf::MatrixOps::Pow(k);
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            std::cout << mtf::MatrixOps::b[i][j] << " \n"[j == n - 1];
}
