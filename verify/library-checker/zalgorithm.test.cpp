// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/zalgorithm

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    std::string s;
    std::cin >> s;
    auto z = mtf::ZFunction(s);
    for (int i = 0; i < static_cast<int>(z.size()); i++)
        std::cout << z[i] << " \n"[i + 1 == static_cast<int>(z.size())];
}
