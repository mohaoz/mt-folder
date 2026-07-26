#import "../../template.typ": snippet, web-only

= 字符串
== KMP
求前缀函数，支持模式串匹配。

- `Kmp(s)[i]` 表示 `s[0..i)` 的 border 长度；
- 匹配复杂度 `O(n + m)`。

#let kmp = ```cpp
auto Kmp(const string& s) {
    int n = s.size();
    vector<int> f(n + 1);
    for (int i = 1, j = 0; i < n; i++) {
        while (j > 0 and s[i] != s[j])
            j = f[j];
        j += (s[i] == s[j]);
        f[i + 1] = j;
    }
    return f;
}
```

#snippet(kmp)
