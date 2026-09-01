#import "../../template.typ": snippet

== Z 函数（exKMP）

求串内或两个串之间的最长公共前缀。

- `ZFunction(s)[i]` 是 `s` 与 `s[i..n)` 的 LCP 长度，约定
  `ZFunction(s)[0] = n`；
- `ExKMP(s, p)[i]` 是 `s[i..n)` 与 `p` 的 LCP 长度；
- 时间复杂度均为线性，返回数组使用 `0-indexed`。

#let z-function = ```cpp
auto ZFunction(const std::string& s) {
    int n = s.size();
    std::vector<int> z(n);
    if (n == 0)
        return z;
    z[0] = n;
    for (int i = 1, l = 0, r = 0; i < n; i++) {
        if (i < r)
            z[i] = std::min(r - i, z[i - l]);
        while (i + z[i] < n and s[z[i]] == s[i + z[i]])
            z[i]++;
        if (i + z[i] > r)
            l = i, r = i + z[i];
    }
    return z;
}

auto ExKMP(const std::string& s, const std::string& p) {
    int n = s.size(), m = p.size();
    auto z = ZFunction(p);
    std::vector<int> lcp(n);
    for (int i = 0, l = 0, r = 0; i < n; i++) {
        if (i < r)
            lcp[i] = std::min(r - i, z[i - l]);
        while (lcp[i] < m and i + lcp[i] < n and
               p[lcp[i]] == s[i + lcp[i]])
            lcp[i]++;
        if (i + lcp[i] > r)
            l = i, r = i + lcp[i];
    }
    // 完全等于 ZFunction(p + '#' + s)
    return lcp;
}
```

#snippet(z-function, id: "z-function")
