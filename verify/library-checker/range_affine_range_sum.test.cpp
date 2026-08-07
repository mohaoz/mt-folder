// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/range_affine_range_sum

#include <mtf_verify.hpp>

using Z = mtf::ModInt<998244353>;

struct Tag {
    Z a{1}, b{0};

    // 语义：先应用当前映射，再应用 rhs。
    auto& operator+=(const Tag& rhs) {
        a = rhs.a * a;
        b = rhs.a * b + rhs.b;
        return *this;
    }
};

struct Node {
    Z sum{0}, size{0};

    friend Node operator+(const Node& lhs, const Node& rhs) {
        return {lhs.sum + rhs.sum, lhs.size + rhs.size};
    }

    auto& operator*=(const Tag& f) {
        sum = f.a * sum + f.b * size;
        return *this;
    }
};

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int n, q;
    std::cin >> n >> q;
    std::vector<Node> init(n);
    for (auto& node : init) {
        std::cin >> node.sum;
        node.size = 1;
    }

    mtf::LazySegTree<Node, Tag> tree(n, std::move(init));
    while (q--) {
        int type, l, r;
        std::cin >> type >> l >> r;
        if (type == 0) {
            Tag f;
            std::cin >> f.a >> f.b;
            tree.Update(l, r, f);
        } else {
            std::cout << tree.Query(l, r).sum << '\n';
        }
    }
}
