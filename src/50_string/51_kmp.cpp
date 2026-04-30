#include <bits/stdc++.h>
using namespace std;

// CIALLO_MD
// # 字符串
// ## KMP
// 求前缀函数，支持模式串匹配。
//
// - `Kmp(s)[i]` 表示 `s[0..i)` 的 border 长度；
// - 匹配复杂度 `O(n + m)`。
// CIALLO_CODE
vector<int> Kmp(const string &s) {
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
// CIALLO_END

void P3375() {
    string s, t;
    cin >> s >> t;
    auto f = Kmp(t);
    for (int i = 0, j = 0; i < (int)s.size(); i++) {
        while (j > 0 and s[i] != t[j])
            j = f[j];
        j += (s[i] == t[j]);
        if (j == (int)t.size()) {
            cout << i - j + 2 << '\n';
            j = f[j];
        }
    }
    for (int i = 1; i <= (int)t.size(); i++)
        cout << f[i] << " \n"[i == (int)t.size()];
}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    P3375();
}
