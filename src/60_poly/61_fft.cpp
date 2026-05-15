#include <bits/stdc++.h>
using namespace std;

// CIALLO_MD
// # 多项式
// ## FFT
// 复数 FFT 求整数多项式卷积。
//
// - 适合普通整数卷积；
// - 返回长度为 `a.size() + b.size() - 1` 的结果；
// - 复杂度 `O(n log n)`。
// CIALLO_CODE
using i64 = int64_t;
using comp = complex<double>;
const double PI = acos(-1);

void Fft(vector<comp>& a, bool inv) {
    int n = a.size();
    for (int i = 1, j = 0; i < n; i++) {
        int bit = n >> 1;
        for (; j & bit; bit >>= 1)
            j ^= bit;
        j ^= bit;
        if (i < j)
            swap(a[i], a[j]);
    }
    for (int len = 2; len <= n; len <<= 1) {
        double ang = 2 * PI / len * (inv ? -1 : 1);
        comp wlen(cos(ang), sin(ang));
        for (int i = 0; i < n; i += len) {
            comp w(1);
            for (int j = 0; j < len / 2; j++) {
                comp u = a[i + j];
                comp v = a[i + j + len / 2] * w;
                a[i + j] = u + v;
                a[i + j + len / 2] = u - v;
                w *= wlen;
            }
        }
    }
    if (inv)
        for (auto& x : a)
            x /= n;
}

auto Convolution(const vector<i64>& a,
                 const vector<i64>& b) {
    if (a.empty() or b.empty())
        return vector<i64>{};
    int need = a.size() + b.size() - 1;
    int n = 1;
    while (n < need)
        n <<= 1;
    vector<comp> fa(a.begin(), a.end()),
        fb(b.begin(), b.end());
    fa.resize(n);
    fb.resize(n);
    Fft(fa, false);
    Fft(fb, false);
    for (int i = 0; i < n; i++)
        fa[i] *= fb[i];
    Fft(fa, true);
    vector<i64> res(need);
    for (int i = 0; i < need; i++)
        res[i] = llround(fa[i].real());
    return res;
}
// CIALLO_END

void P3803() {
    int n, m;
    cin >> n >> m;
    vector<i64> a(n + 1), b(m + 1);
    for (auto& x : a)
        cin >> x;
    for (auto& x : b)
        cin >> x;
    auto c = Convolution(a, b);
    for (int i = 0; i <= n + m; i++)
        cout << c[i] << " \n"[i == n + m];
}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    P3803();
}
