// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/set_xor_min

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int q;
    std::cin >> q;
    mtf::XorTrie trie(q);
    std::unordered_set<int> present;
    present.reserve(q * 2);

    // Trie 求的是最大异或；对 30..0 位全部取反即得最小异或：
    // min(x ^ y) = mask ^ max((x ^ mask) ^ y)。
    constexpr int mask = 0x7fffffff;
    while (q--) {
        int type, x;
        std::cin >> type >> x;
        if (type == 0) {
            if (present.insert(x).second)
                trie.Insert(x);
        } else if (type == 1) {
            if (present.erase(x) > 0)
                trie.Erase(x);
        } else {
            std::cout << (mask ^ trie.Query(x ^ mask)) << '\n';
        }
    }
}
