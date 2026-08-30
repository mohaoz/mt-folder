#import "../../template.typ": snippet, web-only

== 多项式卷积

=== FFT
复数 FFT 求整数多项式卷积。

- `FFT::Convolution(a, b)` 返回长度为 `a.size() + b.size() - 1` 的结果，
  任一输入为空时返回空数组；
- 输入可以包含负数；
- 设补齐后的变换长度为 `L`，复杂度 `O(L log L)`，空间复杂度 `O(L)`；
- 依赖 `double` 精度：需保证 `L * max|a| * max|b|` 不超过约 `1e15`，
  更大范围改用拆系数或 NTT。

#let fft = ```cpp
struct FFT {
    using i64 = int64_t;
    using comp = std::complex<double>;
    static constexpr double PI = std::numbers::pi;

    static void transform(std::vector<comp> &a, bool inv) {
        int n = a.size();
        for (int i = 1, j = 0; i < n; i++) {
            int bit = n >> 1;
            for (; j & bit; bit >>= 1)
                j ^= bit;
            j ^= bit;
            if (i < j)
                std::swap(a[i], a[j]);
        }
        for (int len = 2; len <= n; len <<= 1) {
            double ang = 2 * PI / len * (inv ? 1 : -1);
            comp wlen(std::cos(ang), std::sin(ang));
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
            for (auto &x : a)
                x /= n;
    }

    static auto Convolution(const std::vector<i64> &a,
                            const std::vector<i64> &b) {
        if (a.empty() or b.empty())
            return std::vector<i64>{};
        int need = a.size() + b.size() - 1;
        int n = 1;
        while (n < need)
            n <<= 1;
        std::vector<comp> fa(a.begin(), a.end()), fb(b.begin(), b.end());
        fa.resize(n), fb.resize(n);
        transform(fa, false), transform(fb, false);
        for (int i = 0; i < n; i++)
            fa[i] *= fb[i];
        transform(fa, true);
        std::vector<i64> res(need);
        for (int i = 0; i < need; i++)
            res[i] = std::llround(fa[i].real());
        return res;
    }
};
```

#snippet(fft)

=== NTT
数论变换在素数模数下求多项式卷积，不受浮点误差影响。

- `MOD` 必须是素数；`NTT<MOD>::PrimitiveRoot()` 在编译期求原根；
- `NTT<MOD>::Convolution(a, b)` 会把负数归一化到 `[0, MOD)`，任一输入
  为空时返回空数组；
- 设补齐后的变换长度为 `L`，必须满足 `L | (MOD - 1)`；
- 复杂度 `O(L log L)`，空间复杂度 `O(L)`；常用模数可直接写
  `NTT<998244353>::Convolution(a, b)`。

#let ntt = ```cpp
template <int MOD>
struct NTT {
    using i64 = int64_t;

    static constexpr int pow(i64 a, i64 b) {
        i64 res = 1;
        while (b) {
            if (b & 1)
                res = res * a % MOD;
            a = a * a % MOD;
            b >>= 1;
        }
        return res;
    }

    static consteval int PrimitiveRoot() {
        if constexpr (MOD == 2)
            return 1;
        int x = MOD - 1;
        std::array<int, 32> fac{};
        int cnt = 0;
        for (i64 p = 2; p * p <= x; p++) {
            if (x % p == 0) {
                fac[cnt++] = p;
                while (x % p == 0)
                    x /= p;
            }
        }
        if (x > 1)
            fac[cnt++] = x;
        for (int g = 2;; g++) {
            bool ok = true;
            for (int i = 0; i < cnt; i++) {
                if (pow(g, (MOD - 1) / fac[i]) == 1) {
                    ok = false;
                    break;
                }
            }
            if (ok)
                return g;
        }
    }

    static constexpr int G = PrimitiveRoot();

    static void transform(std::vector<i64> &a, bool inv) {
        int n = a.size();
        for (int i = 1, j = 0; i < n; i++) {
            int bit = n >> 1;
            for (; j & bit; bit >>= 1)
                j ^= bit;
            j ^= bit;
            if (i < j)
                std::swap(a[i], a[j]);
        }
        for (int len = 2; len <= n; len <<= 1) {
            i64 wlen = pow(G, (MOD - 1) / len);
            if (inv)
                wlen = pow(wlen, MOD - 2);
            for (int i = 0; i < n; i += len) {
                i64 w = 1;
                for (int j = 0; j < len / 2; j++) {
                    i64 u = a[i + j];
                    i64 v = a[i + j + len / 2] * w % MOD;
                    a[i + j] = u + v;
                    if (a[i + j] >= MOD)
                        a[i + j] -= MOD;
                    a[i + j + len / 2] = u - v;
                    if (a[i + j + len / 2] < 0)
                        a[i + j + len / 2] += MOD;
                    w = w * wlen % MOD;
                }
            }
        }
        if (inv) {
            i64 in = pow(n, MOD - 2);
            for (auto &x : a)
                x = x * in % MOD;
        }
    }

    static auto Convolution(const std::vector<i64> &a,
                            const std::vector<i64> &b) {
        if (a.empty() or b.empty())
            return std::vector<i64>{};
        int need = a.size() + b.size() - 1;
        int n = 1;
        while (n < need)
            n <<= 1;
        assert((MOD - 1) % n == 0);
        std::vector<i64> fa(n), fb(n);
        for (int i = 0; i < (int)a.size(); i++) {
            i64 x = a[i] % MOD;
            if (x < 0)
                x += MOD;
            fa[i] = x;
        }
        for (int i = 0; i < (int)b.size(); i++) {
            i64 x = b[i] % MOD;
            if (x < 0)
                x += MOD;
            fb[i] = x;
        }
        transform(fa, false);
        transform(fb, false);
        for (int i = 0; i < n; i++)
            fa[i] = fa[i] * fb[i] % MOD;
        transform(fa, true);
        fa.resize(need);
        return fa;
    }
};
```

#snippet(ntt)
