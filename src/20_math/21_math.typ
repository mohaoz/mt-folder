#import "../../template.typ": snippet, web-only

= 数学
== 线性筛
初始化 `[2, N]` 内质数和非质数标记。

- `pri` 存储所有质数；
- `np[x]` 表示 `x` 是否不是质数；
- 固定上界作为模板参数，使用 `Sieve<N> sieve;` 初始化；
- 复杂度 `O(N)`。

#let sieve = ```cpp
template <int N>
struct Sieve {
    std::vector<int> pri;
    bool np[N + 1]{};

    Sieve() {
        np[0] = np[1] = true;
        for (int i = 2; i <= N; i++) {
            if (!np[i])
                pri.emplace_back(i);
            for (int p : pri) {
                if (i * p > N)
                    break;
                np[i * p] = true;
                if (i % p == 0)
                    break;
            }
        }
    }
};
```

#snippet(sieve, header: "math/math.hpp")

== 因数/约数分解
`Factor(n)` 返回质因数分解，`Divisor(n)` 返回大于 `1` 且小于等于 `n` 的约数。

- 适合 `int` 范围内的试除；
- 复杂度 `O(sqrt n)`。

#let factorization = ```cpp
inline auto Factor(int n) {
    std::vector<std::pair<int, int>> res;
    for (int i = 2; i * i <= n; i++) {
        int cur = 0;
        while (n % i == 0) {
            cur++;
            n /= i;
        }
        if (cur != 0)
            res.emplace_back(i, cur);
    }
    if (n > 1)
        res.emplace_back(n, 1);
    return res;
}

inline auto Divisor(int n) {
    std::vector<int> res;
    for (int i = 2; i * i <= n; i++) {
        if (n % i == 0) {
            res.emplace_back(i);
            if (i * i != n)
                res.emplace_back(n / i);
        }
    }
    std::sort(res.begin(), res.end());
    return res;
}
```

#snippet(factorization, header: "math/math.hpp")

== 扩展欧几里得
返回 `gcd(a, b)`，并求出 `ax + by = gcd(a, b)` 的一组解。

- 参数可以是整数类型；
- 复杂度 `O(log min(a, b))`。

#let exgcd = ```cpp
template <class T>
inline T ExGCD(T a, T b, T& x, T& y) {
    if (b == 0) {
        x = 1, y = 0;
        return a;
    }
    auto d = ExGCD(b, a % b, y, x);
    y -= a / b * x;
    return d;
}
```

#snippet(exgcd, header: "math/math.hpp")

== 快速幂
计算 `a^b mod p`。

- `b >= 0`；
- 复杂度 `O(log b)`。

#let powmod = ```cpp
inline auto PowMod(i64 a, i64 b, int p) {
    i64 res = 1;
    while (b) {
        if (b & 1)
            res = res * a % p;
        b = b >> 1;
        a = a * a % p;
    }
    return res;
}
```

#snippet(powmod, header: "math/math.hpp")
