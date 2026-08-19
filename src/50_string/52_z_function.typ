#import "../../template.typ": snippet

== Z 函数（exKMP）

求串内或两个串之间的最长公共前缀。

- `ZFunction(s)[i]` 是 `s` 与 `s[i..n)` 的 LCP 长度，约定
  `ZFunction(s)[0] = n`；
- `ExKmp(text, pattern)[i]` 是 `text[i..n)` 与 `pattern` 的 LCP 长度；
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
        while (i + z[i] < n && s[z[i]] == s[i + z[i]])
            z[i]++;
        if (i + z[i] > r)
            l = i, r = i + z[i];
    }
    return z;
}

auto ExKmp(const std::string& text,
           const std::string& pattern) {
    int n = text.size(), m = pattern.size();
    auto z = ZFunction(pattern);
    std::vector<int> lcp(n);
    for (int i = 0, l = 0, r = 0; i < n; i++) {
        if (i < r)
            lcp[i] = std::min(r - i, z[i - l]);
        while (lcp[i] < m && i + lcp[i] < n &&
               pattern[lcp[i]] == text[i + lcp[i]])
            lcp[i]++;
        if (i + lcp[i] > r)
            l = i, r = i + lcp[i];
    }
    return lcp;
}
```

#snippet(z-function, id: "z-function")
