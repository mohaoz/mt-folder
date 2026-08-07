// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/point_set_range_composite

#include <mtf_verify.hpp>

using Z = mtf::ModInt<998244353>;

// 一次函数 x -> a x + b；区间合成后表示“先应用左端的函数”。
struct Affine {
    Z a{1}, b{0};

    friend Affine operator+(const Affine& lhs, const Affine& rhs) {
        return {rhs.a * lhs.a, rhs.a * lhs.b + rhs.b};
    }
};

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int n, q;
    std::cin >> n >> q;
    std::vector<Affine> functions(n);
    for (auto& f : functions)
        std::cin >> f.a >> f.b;

    mtf::SegTree<Affine> tree(n, std::move(functions));
    while (q--) {
        int type;
        std::cin >> type;
        if (type == 0) {
            int p;
            Affine f;
            std::cin >> p >> f.a >> f.b;
            tree.Set(p, f);
        } else {
            int l, r;
            Z x;
            std::cin >> l >> r >> x;
            const auto f = tree.Query(l, r);
            std::cout << f.a * x + f.b << '\n';
        }
    }
}
