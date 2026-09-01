#import "../../template.typ": snippet, web-only

== KMP
求前缀函数，支持模式串匹配。

- `PrefixFunction(s)` 返回长度为 `s.size() + 1` 的数组，`f[i]` 表示
  `s[0..i)` 的 border 长度；
- `KMP(s, p)` 返回非空模式串 `p` 在文本串 `s` 中所有匹配的起始下标；
- 前缀函数复杂度 `O(|s|)`，模式匹配复杂度 `O(|s| + |p|)`。

#let kmp = ```cpp
auto PrefixFunction(const std::string& s) {
    int n = s.size();
    std::vector<int> f(n + 1);
    for (int i = 1, j = 0; i < n; i++) {
        while (j > 0 and s[i] != s[j]) {
            j = f[j];
        }
        j += (s[i] == s[j]);
        f[i + 1] = j;
    }
    return f;
}

auto KMP(const std::string& s, const std::string& p) {
    auto f = PrefixFunction(p);
    std::vector<int> pos;
    for (int i = 0, j = 0; i < s.size(); i++) {
        while (j > 0 and s[i] != p[j])
            j = f[j];
        j += (s[i] == p[j]);
        if (j == p.size()) {
            pos.emplace_back(i - j + 1);
            j = f[j];
        }
    }
    // 实则令 f = PrefixFunction(p + '#' + s)
    // f[p.size() + 1 + i] == p.size() 则代表有一次匹配
    return pos;
}
```

#snippet(kmp)
