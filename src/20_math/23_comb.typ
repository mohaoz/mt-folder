#import "../../template.typ": snippet, web-only

== 组合数
按是否已使用 `ModInt` 在下面两份模板中选择一份。

=== 组合数（ModInt）
基于 ModInt 预处理阶乘和逆阶乘。

- `Z` 需要支持乘法、除法；
- `C(n, k)` 返回组合数；
- 预处理 `O(n)`，单次查询 `O(1)`。

#let comb = ```cpp
template <class Z>
struct Comb {
    std::vector<Z> fac, ifac;

    Comb(int n) : fac(n + 1), ifac(n + 1) {
        fac[0] = 1;
        for (int i = 1; i <= n; i++)
            fac[i] = fac[i - 1] * i;
        ifac[n] = Z(1) / fac[n];
        for (int i = n; i >= 1; i--)
            ifac[i - 1] = ifac[i] * i;
    }

    auto C(int n, int k) const {
        if (k < 0 or k > n)
            return Z{};
        return fac[n] * ifac[k] * ifac[n - k];
    }

    auto A(int n, int k) const {
        if (k < 0 or k > n)
            return Z{};
        return fac[n] * ifac[n - k];
    }
};
```

#snippet(comb)

=== 组合数（All in One）
不依赖 `ModInt` 的定模版本，与上一份模板二选一。

- 模板参数 `N` 是预处理上界，`MOD` 必须是素数且 `N < MOD`；
- `C(n, k)` 返回组合数，参数越界时返回 `0`；
- 预处理 `O(N)`，单次查询 `O(1)`。

#let comb-all-in-one = ```cpp
template <int N, int MOD>
struct CombInt {
    std::vector<int> fac, ifac;

    CombInt() : fac(N + 1), ifac(N + 1) {
        fac[0] = 1;
        for (int i = 1; i <= N; i++)
            fac[i] = 1LL * fac[i - 1] * i % MOD;
        ifac[N] = pow(fac[N], MOD - 2);
        for (int i = N; i >= 1; i--)
            ifac[i - 1] = 1LL * ifac[i] * i % MOD;
    }

    int C(int n, int k) const {
        if (n < 0 or n > N or k < 0 or k > n)
            return 0;
        return 1LL * fac[n] * ifac[k] % MOD *
               ifac[n - k] % MOD;
    }

    static int pow(int a, int b) {
        int res = 1;
        while (b) {
            if (b & 1)
                res = 1LL * res * a % MOD;
            a = 1LL * a * a % MOD;
            b >>= 1;
        }
        return res;
    }
};
```

#snippet(comb-all-in-one)

=== 组合数（大 n、小 k）
不预处理阶乘，适合 `n` 很大、`k` 较小且查询次数不多的场景。

- `MOD` 必须是素数，要求 `0 <= n < MOD`；
- `CombLarge<MOD>(n, k)` 返回组合数，参数越界时返回 `0`；
- 单次查询复杂度 `O(min(k, n - k) + log MOD)`，空间复杂度 `O(1)`。

#let comb-large = ```cpp
template <int MOD>
int CombLarge(int n, int k) {
    if (n < 0 or n >= MOD or k < 0 or k > n)
        return 0;
    k = std::min(k, n - k);
    int num = 1, den = 1;
    for (int i = 1; i <= k; i++) {
        num = 1LL * num * (n - k + i) % MOD;
        den = 1LL * den * i % MOD;
    }
    auto pow = [](int a, int b) {
        int res = 1;
        while (b) {
            if (b & 1)
                res = 1LL * res * a % MOD;
            a = 1LL * a * a % MOD;
            b >>= 1;
        }
        return res;
    };
    return 1LL * num * pow(den, MOD - 2) % MOD;
}
```

#snippet(comb-large)
