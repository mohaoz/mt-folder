#pragma once

#include <vector>
#include <algorithm>

using i8 = signed char;
using u8 = unsigned char;
using i32 = signed;
using u32 = unsigned;
using i64 = long long;
using u64 = unsigned long long;
using i128 = __int128;
using u128 = unsigned __int128;

// CIALLO_MD
// # 数学
// ## 线性筛
// CIALLO_CODE
inline void Sieve(int n, auto &&pri, auto &&mp) {
    mp.resize(n + 1);
    for (int i = 2; i <= n; i++) {
        if (!mp[i])
            pri.emplace_back(i);
        for (int p : pri) {
            if (i * p > n)
                break;
            mp[i * p] = p;
            if (i % p == 0)
                break;
        }
    }
}
// CIALLO_END

// CIALLO_MD
// ## 因数/约数分解
// CIALLO_CODE
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
// CIALLO_END

// CIALLO_MD
// ## 扩展欧几里得
// CIALLO_CODE
inline auto ExGCD(auto a, auto b, auto &x, auto &y) {
    if (b == 0) {
        x = 1, y = 0;
        return a;
    }
    auto d = exgcd(b, a % b, y, x);
    y -= a / b * x;
    return d;
}
// CIALLO_END

// CIALLO_MD
// ## 快速幂
// CIALLO_CODE
inline int PowMod(i64 a, i64 b, int p) {
    i64 res = 1;
    while (b) {
        if (b & 1) res = res * a % p;
        b = b >> 1;
        a = a * a % p;
    }
    return res;
}
// CIALLO_END
