// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/unionfind

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    int n, q;
    std::cin >> n >> q;
    mtf::DSU dsu(n);
    while (q--) {
        int type, u, v;
        std::cin >> type >> u >> v;
        if (type == 0)
            dsu.Merge(u, v);
        else
            std::cout << (dsu.Find(u) == dsu.Find(v)) << '\n';
    }
}
