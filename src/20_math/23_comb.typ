#import "../../template.typ": snippet, web-only

== 组合数
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
