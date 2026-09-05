#import "../../template.typ": snippet, web-only

== 线性筛
初始化 $[2, N]$ 内质数和非质数标记。

- `pri` 存储所有质数；
- `np[x]` 表示 `x` 是否不是质数；
- 固定上界作为模板参数，使用 `Sieve<N> sieve;` 初始化；
- 复杂度 $O(N)$。

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

#snippet(sieve)

== 因数/约数分解
`Factor(n)` 返回质因数分解，`Divisor(n)` 返回满足 $1 < d <= n$ 的约数 $d$。

- 适合 `int` 范围内的试除；
- 复杂度 $O(sqrt(n))$。

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

#snippet(factorization)

=== 批量筛因子

`Divisors(n)[x]` 存储 $x$ 的全部正因子，时间与空间复杂度均为
$O(n log n)$。

#let divisors = ```cpp
inline auto Divisors(int n) {
    std::vector<std::vector<int>> res(n + 1);
    for (int d = 1; d <= n; d++)
        for (int x = d; x <= n; x += d)
            res[x].emplace_back(d);
    return res;
}
```

#snippet(divisors)

=== 欧拉函数

线性筛求出 `phi[x]` ($1 <= x <= n$)，其中 `phi[x]` 表示 $[1, x]$
中与 $x$ 互质的整数个数。要求 $n >= 1$，复杂度为 $O(n)$。

#let euler-phi = ```cpp
inline auto EulerPhi(int n) {
    std::vector<int> phi(n + 1), pri;
    std::vector<bool> np(n + 1);
    phi[1] = 1;
    for (int i = 2; i <= n; i++) {
        if (!np[i]) {
            pri.emplace_back(i);
            phi[i] = i - 1;
        }
        for (int p : pri) {
            if (p > n / i)
                break;
            np[i * p] = true;
            if (i % p == 0) {
                phi[i * p] = phi[i] * p;
                break;
            }
            phi[i * p] = phi[i] * (p - 1);
        }
    }
    return phi;
}
```

#snippet(euler-phi)

== 扩展欧几里得
返回 `gcd(a, b)`，并求出 $a x + b y = gcd(a, b)$ 的一组解。

- 参数可以使用整数类型；
- 复杂度 $O(log min(a, b))$。

#let exgcd = ```cpp
inline auto ExGCD(auto a, auto b, auto& x, auto& y) {
    if (b == 0) {
        x = 1, y = 0;
        return a;
    }
    auto d = ExGCD(b, a % b, y, x);
    y -= a / b * x;
    return d;
}
```

#snippet(exgcd)

== 快速幂
计算 $a^b mod p$。

- $b >= 0$；
- 复杂度 $O(log b)$。

#let powmod = ```cpp
using i64 = int64_t;

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

#snippet(powmod)
