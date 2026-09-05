#import "../../template.typ": snippet

== 双模字符串哈希
预处理多项式前缀哈希，支持子串查询与哈希拼接。

- `Get(l, r)` 返回子串 $s[l, r)$ 的双模哈希值；
- `Merge(a, b, lenB)` 返回拼接串 $a + b$ 的哈希值，`lenB` 是 $b$ 的长度；
- `Merge` 使用的长度不能超过当前实例预处理的字符串长度；
- 预处理时间、空间复杂度均为 $O(n)$，单次查询或拼接为 $O(1)$。

#let string-hash = ```cpp
struct StringHash {
    using Hash = std::pair<int, int>;
    static constexpr int BASE = 131;
    static constexpr int MOD1 = 998244353;
    static constexpr int MOD2 = 1000000007;

    std::vector<int> h1, h2, p1, p2;

    StringHash(const std::string& s)
        : h1(s.size() + 1), h2(s.size() + 1),
          p1(s.size() + 1), p2(s.size() + 1) {
        p1[0] = p2[0] = 1;
        for (int i = 1; i <= (int)s.size(); i++) {
            p1[i] = 1LL * p1[i - 1] * BASE % MOD1;
            p2[i] = 1LL * p2[i - 1] * BASE % MOD2;
            h1[i] = (1LL * h1[i - 1] * BASE +
                     (unsigned char)s[i - 1]) % MOD1;
            h2[i] = (1LL * h2[i - 1] * BASE +
                     (unsigned char)s[i - 1]) % MOD2;
        }
    }

    Hash Get(int l, int r) const {
        int x = (h1[r] - 1LL * h1[l] * p1[r - l] % MOD1 +
                 MOD1) % MOD1;
        int y = (h2[r] - 1LL * h2[l] * p2[r - l] % MOD2 +
                 MOD2) % MOD2;
        return {x, y};
    }

    Hash Merge(Hash a, Hash b, int lenB) const {
        return {
            int((1LL * a.first * p1[lenB] + b.first) % MOD1),
            int((1LL * a.second * p2[lenB] + b.second) % MOD2)
        };
    }
};
```

#snippet(string-hash)
