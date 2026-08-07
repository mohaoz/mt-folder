
= 杂项
== 约定

+ C++ 版本：`gnu++20`
+ 格式：
   + 缩进宽度为 4 个空格；
   + 大括号换行；
   + 一元运算符不空格，其他运算符空一格；
+ 命名：
   + 遵循 `GoLang` 的命名规范；
+ 其他：
   + 使用 `0-indexed` 的左闭右开区间；
   + 使用解绑同步流的 `std::cin` 和 `std::cout` 输入输出；
   + 使用 `using namespace std;`；
   + 使用局部变量而非全局变量，局部 `lambda` 而非全局函数；
   + 使用 `emplace` 而非 `push`，集合查重使用 `contains`；
   + 若键值较小，使用 `vector` 而非 `map`；不要求顺序的情况下可以用 `unordered_` 系列，但在 Codeforces 上记得使用随机模数；

== 初始代码

```cpp
#include <bits/stdc++.h>
using namespace std;

#define int long long

int T{0};
void solve() {}

signed main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    if (!T)
        cin >> T;
    while (T--)
        solve();
}
```


== 类型定义

```cpp
using i8 = signed char;
using u8 = unsigned char;
using i32 = signed;
using u32 = unsigned;
using i64 = int64_t;
using u64 = uint64_t;
using i128 = __int128;
using u128 = unsigned __int128;
```


== 随机数生成

```cpp
using u64 = uint64_t;

// std::mt19937
mt19937 rng(std::chrono::steady_clock::now()
                .time_since_epoch()
                .count());
// splitmix64
struct custom_hash {
    static auto splitmix64(u64 x) {
        x += 0x9e3779b97f4a7c15;
        x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9;
        x = (x ^ (x >> 27)) * 0x94d049bb133111eb;
        return x ^ (x >> 31);
    }

    auto operator()(u64 x) const {
        static const u64 SEED =
            std::chrono::high_resolution_clock::
                now()
                    .time_since_epoch()
                    .count();
        return splitmix64(x + SEED);
    }
};
```


== 二分答案

```cpp
int l, r, ans;
bool check(int);
while (l <= r) {
    int mid = l + (r - l) / 2;
    if (check(mid)) {
        ans = mid;
        // l 和 r 取决于方向
        l = mid + 1;
    } else {
        r = mid - 1;
    }
}
```


== Lambda 递归

```cpp
std::vector<std::vector<int>> adj;
auto dfs1 = [&](auto&& self, int x,
                int p) -> void {
    for (auto y : adj[x]) {
        if (y == p)
            continue;
        self(self, y, x);
    }
};
dfs1(dfs1, 0, 0);
// std::function 版本
// 没有使用的必要
std::function<void(int, int)> dfs2 =
    [&](int x, int p) {
        for (auto y : adj[x]) {
            if (y == p)
                continue;
            dfs2(y, x);
        }
    };
```


== Bitmask 集合枚举

默认 `n <= 30`，用 `int` 的低 `n` 位表示集合；需要更大位宽时把集合变量统一改为 `i64 / u64`。

=== `<bit>` 与 GNU builtin

C++20 的 `<bit>` 接口只接受无符号整数。默认 `int` 位宽时把参数转为
`unsigned`；使用 `u64` 时直接传入 `u64`，不再区分 builtin 的普通版与
`ll` 版。

- `std::popcount((unsigned)x)` 对应 `__builtin_popcount(x)`；
- `std::countr_zero((unsigned)x)` 对应 `__builtin_ctz(x)`；
- `std::countl_zero((unsigned)x)` 对应 `__builtin_clz(x)`；
- `std::bit_width((unsigned)x) - 1` 对应 `__lg(x)`，要求 `x > 0`；
- `std::has_single_bit((unsigned)x)` 判断是否为 2 的幂；
- `std::bit_floor((unsigned)x)` 和 `std::bit_ceil((unsigned)x)` 分别求不超过、
  不小于 `x` 的 2 的幂。

=== 基础操作

```cpp
int ALL = (1LL << n) - 1;

S & -S;       // lowbit
S & (S - 1);  // 删除最低位的 1
```

=== 子集 / 真子集

枚举 `S` 的所有非空子集：

```cpp
for (int T = S; T; T = (T - 1) & S) {
}
```

枚举 `S` 的所有非空真子集：

```cpp
for (int T = (S - 1) & S; T; T = (T - 1) & S) {
}
```

=== 枚举元素

```cpp
for (int T = S; T; T &= T - 1) {
    int i = std::countr_zero((unsigned)T);
}
```

=== 集合二分

枚举有序二分 `(A, B)`：

```cpp
for (int A = (S - 1) & S; A; A = (A - 1) & S) {
    int B = S ^ A;
}
```

无序二分去重：固定 `S` 的最低位元素属于 `A`。

```cpp
int bit = S & -S;

for (int A = (S - 1) & S; A; A = (A - 1) & S) {
    if (!(A & bit))
        continue;

    int B = S ^ A;
}
```

=== 超集 / 不相交集合

枚举与 `S` 不相交的所有非空集合：

```cpp
int rest = ALL ^ S;

for (int T = rest; T; T = (T - 1) & rest) {
}
```

枚举 `S` 的所有超集（包含 `S` 和 `ALL`）：

```cpp
for (int T = S;; T = (T + 1) | S) {
    // T ⊇ S
    if (T == ALL)
        break;
}
```

=== 固定 popcount（Gosper）

```cpp
if (k == 0) {
    int S = 0;  // 唯一状态
} else {
    for (int S = (1LL << k) - 1; S < 1LL << n;) {
        // popcount(S) == k

        int low = S & -S;
        int nxt = S + low;
        if (nxt >= 1LL << n)
            break;

        S = nxt | (((nxt ^ S) >> 2) / low);
    }
}
```

复杂度为 $O(binom(n, k))$。

=== 复杂度

- 枚举一个 `S` 的所有子集：`O(2^popcount(S))`；
- 枚举所有 `S` 及其子集：`O(3^n)`；
- 固定 `popcount = k`：`O(C(n, k))`。

```cpp
for (int S = 0; S < 1LL << n; S++)
    for (int T = S; T; T = (T - 1) & S) {
    }
```

上述双重枚举的总复杂度为 $O(3^n)$。

=== 坑点

- `__builtin_ctz(0)` 与 `__builtin_ctzll(0)` 未定义；
  `std::countr_zero(0u)` 则返回参数类型的位数；
- 只有 `T ⊆ S` 时，`S ^ T` 才等于 `S \ T`；
- 使用 `1LL << n`，不要写 `1 << n`；
- `n >= 31` 时改用 `i64 / u64`；`i64` 仍要求 `n < 63`；
- SOS DP 必须先枚举位，再枚举状态；
- Gosper 需要单独处理 `k == 0`。

== SOS DP

对大小为 `1LL << n` 的数组原地做变换，只保留四个现场常用操作：

- 子集 Zeta：$f[S] = sum_(T subset.eq S) a[T]$；
- 子集 Möbius：子集 Zeta 的逆变换；
- 超集 Zeta：$f[S] = sum_(T supset.eq S) a[T]$；
- 超集 Möbius：超集 Zeta 的逆变换。

```cpp
void SubsetZeta(auto& f, int n) {
    for (int i = 0; i < n; i++) {
        for (int S = 0; S < 1LL << n; S++) {
            if (S >> i & 1) {
                f[S] += f[S ^ (1LL << i)];
            }
        }
    }
}

void SubsetMobius(auto& f, int n) {
    for (int i = 0; i < n; i++) {
        for (int S = 0; S < 1LL << n; S++) {
            if (S >> i & 1) {
                f[S] -= f[S ^ (1LL << i)];
            }
        }
    }
}

void SupersetZeta(auto& f, int n) {
    for (int i = 0; i < n; i++) {
        for (int S = 0; S < 1LL << n; S++) {
            if (!(S >> i & 1)) {
                f[S] += f[S | (1LL << i)];
            }
        }
    }
}

void SupersetMobius(auto& f, int n) {
    for (int i = 0; i < n; i++) {
        for (int S = 0; S < 1LL << n; S++) {
            if (!(S >> i & 1)) {
                f[S] -= f[S | (1LL << i)];
            }
        }
    }
}
```


朴素地对所有 `S` 枚举子集是 `O(3^n)`，SOS DP 是 `O(n * 2^n)`。


= 数学
== 线性筛
初始化 `[2, N]` 内质数和非质数标记。

- `pri` 存储所有质数；
- `np[x]` 表示 `x` 是否不是质数；
- 固定上界作为模板参数，使用 `Sieve<N> sieve;` 初始化；
- 复杂度 `O(N)`。

```cpp
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


== 因数/约数分解
`Factor(n)` 返回质因数分解，`Divisor(n)` 返回大于 `1` 且小于等于 `n` 的约数。

- 适合 `int` 范围内的试除；
- 复杂度 `O(sqrt n)`。

```cpp
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

=== 批量筛因子

`Divisors(n)[x]` 存储 `x` 的全部正因子，时间与空间复杂度均为
`O(n log n)`。

```cpp
inline auto Divisors(int n) {
    std::vector<std::vector<int>> res(n + 1);
    for (int d = 1; d <= n; d++)
        for (int x = d; x <= n; x += d)
            res[x].emplace_back(d);
    return res;
}
```

=== 欧拉函数

线性筛求出 `phi[1..n]`，其中 `phi[x]` 表示 `[1, x]` 中与 `x` 互质的
整数个数。要求 `n >= 1`，复杂度为 `O(n)`。

```cpp
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


== 扩展欧几里得
返回 `gcd(a, b)`，并求出 `ax + by = gcd(a, b)` 的一组解。

- 参数可以使用整数类型；
- 复杂度 `O(log min(a, b))`。

```cpp
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


== 快速幂
计算 `a^b mod p`。

- `b >= 0`；
- 复杂度 `O(log b)`。

```cpp
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



== ModInt

固定或动态模数整数，支持四则运算、输入输出和比较。

- `ModInt<P>` 使用 `u32` 模数，`ModInt64<P>` 使用 `u64` 模数；
- `DynModInt<Id>::setMod(P)` 设置动态模数，不同 `Id` 维护不同模数；
- `ModInt<P>` 与动态模数要求 `0 < P <= INT_MAX`，
  `ModInt64<P>` 要求 `0 < P <= INT64_MAX`；
- 除法要求除数与模数互质；
- `ModInt64` 使用长双精度近似规避乘法溢出。

```cpp
using i64 = int64_t;
using u64 = uint64_t;
using u32 = unsigned;

using u128 = unsigned __int128;
using i128 = __int128;

template<class T>
constexpr T power(T a, u64 b, T res = 1) {
    for (; b != 0; b /= 2, a *= a) {
        if (b & 1) {
            res *= a;
        }
    }
    return res;
}

template<u32 P>
constexpr u32 mulMod(u32 a, u32 b) {
    return u64(a) * b % P;
}

template<u64 P>
constexpr u64 mulMod(u64 a, u64 b) {
    u64 res = a * b -
        u64(1.L * a * b / P - 0.5L) * P;
    res %= P;
    return res;
}

constexpr i64 safeMod(i64 x, i64 m) {
    x %= m;
    if (x < 0) {
        x += m;
    }
    return x;
}

constexpr std::pair<i64, i64> invGcd(i64 a, i64 b) {
    a = safeMod(a, b);
    if (a == 0) {
        return {b, 0};
    }

    i64 s = b, t = a;
    i64 m0 = 0, m1 = 1;

    while (t) {
        i64 u = s / t;
        s -= t * u;
        m0 -= m1 * u;

        std::swap(s, t);
        std::swap(m0, m1);
    }

    if (m0 < 0) {
        m0 += b / s;
    }

    return {s, m0};
}

template<std::unsigned_integral U, U P>
struct ModIntBase {
public:
    constexpr ModIntBase() : x(0) {}

    template<std::unsigned_integral T>
    constexpr ModIntBase(T x_) : x(x_ % mod()) {}

    template<std::signed_integral T>
    constexpr ModIntBase(T x_) {
        using S = std::make_signed_t<U>;
        S v = x_ % S(mod());
        if (v < 0) {
            v += mod();
        }
        x = v;
    }

    constexpr static U mod() {
        return P;
    }

    constexpr U val() const {
        return x;
    }

    constexpr ModIntBase operator-() const {
        ModIntBase res;
        res.x = (x == 0 ? 0 : mod() - x);
        return res;
    }

    constexpr ModIntBase inv() const {
        auto v = invGcd(x, mod());
        assert(v.first == 1);
        return v.second;
    }

    constexpr ModIntBase &operator*=(
        const ModIntBase &rhs) & {
        x = mulMod<mod()>(x, rhs.val());
        return *this;
    }

    constexpr ModIntBase &operator+=(
        const ModIntBase &rhs) & {
        x += rhs.val();
        if (x >= mod()) {
            x -= mod();
        }
        return *this;
    }

    constexpr ModIntBase &operator-=(
        const ModIntBase &rhs) & {
        x -= rhs.val();
        if (x >= mod()) {
            x += mod();
        }
        return *this;
    }

    constexpr ModIntBase &operator/=(
        const ModIntBase &rhs) & {
        return *this *= rhs.inv();
    }

    friend constexpr ModIntBase operator*(
        ModIntBase lhs, const ModIntBase &rhs) {
        lhs *= rhs;
        return lhs;
    }

    friend constexpr ModIntBase operator+(
        ModIntBase lhs, const ModIntBase &rhs) {
        lhs += rhs;
        return lhs;
    }

    friend constexpr ModIntBase operator-(
        ModIntBase lhs, const ModIntBase &rhs) {
        lhs -= rhs;
        return lhs;
    }

    friend constexpr ModIntBase operator/(
        ModIntBase lhs, const ModIntBase &rhs) {
        lhs /= rhs;
        return lhs;
    }

    friend constexpr std::istream &operator>>(
        std::istream &is, ModIntBase &a) {
        i64 i;
        is >> i;
        a = i;
        return is;
    }

    friend constexpr std::ostream &operator<<(
        std::ostream &os, const ModIntBase &a) {
        return os << a.val();
    }

    friend constexpr bool operator==(
        const ModIntBase &lhs, const ModIntBase &rhs) {
        return lhs.val() == rhs.val();
    }

    friend constexpr std::strong_ordering operator<=>(
        const ModIntBase &lhs, const ModIntBase &rhs) {
        return lhs.val() <=> rhs.val();
    }

private:
    U x;
};

template<u32 P>
using ModInt = ModIntBase<u32, P>;

template<u64 P>
using ModInt64 = ModIntBase<u64, P>;

struct Barrett {
public:
    Barrett(u32 m_) : m(m_), im((u64)(-1) / m_ + 1) {}

    constexpr u32 mod() const {
        return m;
    }

    constexpr u32 mul(u32 a, u32 b) const {
        u64 z = a;
        z *= b;

        u64 x = u64((u128(z) * im) >> 64);

        u32 v = u32(z - x * m);
        if (m <= v) {
            v += m;
        }
        return v;
    }

private:
    u32 m;
    u64 im;
};

template<u32 Id>
struct DynModInt {
public:
    constexpr DynModInt() : x(0) {}

    template<std::unsigned_integral T>
    constexpr DynModInt(T x_) : x(x_ % mod()) {}

    template<std::signed_integral T>
    constexpr DynModInt(T x_) {
        i64 v = x_ % i64(mod());
        if (v < 0) {
            v += mod();
        }
        x = v;
    }

    constexpr static void setMod(u32 m) {
        bt = m;
    }

    static u32 mod() {
        return bt.mod();
    }

    constexpr u32 val() const {
        return x;
    }

    constexpr DynModInt operator-() const {
        DynModInt res;
        res.x = (x == 0 ? 0 : mod() - x);
        return res;
    }

    constexpr DynModInt inv() const {
        auto v = invGcd(x, mod());
        assert(v.first == 1);
        return v.second;
    }

    constexpr DynModInt &operator*=(
        const DynModInt &rhs) & {
        x = bt.mul(x, rhs.val());
        return *this;
    }

    constexpr DynModInt &operator+=(
        const DynModInt &rhs) & {
        x += rhs.val();
        if (x >= mod()) {
            x -= mod();
        }
        return *this;
    }

    constexpr DynModInt &operator-=(
        const DynModInt &rhs) & {
        x -= rhs.val();
        if (x >= mod()) {
            x += mod();
        }
        return *this;
    }

    constexpr DynModInt &operator/=(
        const DynModInt &rhs) & {
        return *this *= rhs.inv();
    }

    friend constexpr DynModInt operator*(
        DynModInt lhs, const DynModInt &rhs) {
        lhs *= rhs;
        return lhs;
    }

    friend constexpr DynModInt operator+(
        DynModInt lhs, const DynModInt &rhs) {
        lhs += rhs;
        return lhs;
    }

    friend constexpr DynModInt operator-(
        DynModInt lhs, const DynModInt &rhs) {
        lhs -= rhs;
        return lhs;
    }

    friend constexpr DynModInt operator/(
        DynModInt lhs, const DynModInt &rhs) {
        lhs /= rhs;
        return lhs;
    }

    friend constexpr std::istream &operator>>(
        std::istream &is, DynModInt &a) {
        i64 i;
        is >> i;
        a = i;
        return is;
    }

    friend constexpr std::ostream &operator<<(
        std::ostream &os, const DynModInt &a) {
        return os << a.val();
    }

    friend constexpr bool operator==(
        const DynModInt &lhs, const DynModInt &rhs) {
        return lhs.val() == rhs.val();
    }

    friend constexpr std::strong_ordering operator<=>(
        const DynModInt &lhs, const DynModInt &rhs) {
        return lhs.val() <=> rhs.val();
    }

private:
    u32 x;
    static Barrett bt;
};

template<u32 Id>
Barrett DynModInt<Id>::bt = 998244353;

using Z = ModInt<998244353>;
```


== 组合数
基于 ModInt 预处理阶乘和逆阶乘。

- `Z` 需要支持乘法、除法；
- `C(n, k)` 返回组合数；
- 预处理 `O(n)`，单次查询 `O(1)`。

```cpp
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


== 线性基
维护异或线性空间。

- `Insert(x)` 返回 `x` 是否使秩增加；
- `Contains(x)` 判断 `x` 能否由当前线性基异或得到；
- `MaxXor(x)` 返回 `x` 与线性空间中某个元素异或后的最大值。

=== `u64` 版本
位数不超过 64 时使用，最高位默认为 `63`。

```cpp
using u64 = uint64_t;

template <class T = u64, int LOG = 63>
struct LinearBasis {
    std::array<T, LOG + 1> p{};
    int rank = 0;

    bool Insert(T x) {
        for (int i = LOG; i >= 0; i--) {
            if (((x >> i) & 1) == 0)
                continue;
            if (!p[i]) {
                p[i] = x;
                rank++;
                return true;
            }
            x ^= p[i];
        }
        return false;
    }

    bool Contains(T x) const {
        for (int i = LOG; i >= 0; i--) {
            if (((x >> i) & 1) == 0)
                continue;
            if (!p[i])
                return false;
            x ^= p[i];
        }
        return true;
    }

    T MaxXor(T x = 0) const {
        for (int i = LOG; i >= 0; i--)
            if ((x ^ p[i]) > x)
                x ^= p[i];
        return x;
    }

    std::vector<T> Basis() const {
        std::vector<T> res;
        for (int i = 0; i <= LOG; i++)
            if (p[i])
                res.emplace_back(p[i]);
        return res;
    }
};
```


=== `bitset` 版本
位数超过 64 且编译期已知时使用；`N` 是总位数，最高位为 `N - 1`。

```cpp
template <int N>
struct BitsetLinearBasis {
    using B = std::bitset<N>;

    std::array<B, N> p{};
    int rank = 0;

    bool Insert(B x) {
        for (int i = N - 1; i >= 0; i--) {
            if (!x[i])
                continue;
            if (p[i].none()) {
                p[i] = x;
                rank++;
                return true;
            }
            x ^= p[i];
        }
        return false;
    }

    bool Contains(B x) const {
        for (int i = N - 1; i >= 0; i--) {
            if (!x[i])
                continue;
            if (p[i].none())
                return false;
            x ^= p[i];
        }
        return true;
    }

    B MaxXor(B x = {}) const {
        for (int i = N - 1; i >= 0; i--)
            if (!x[i] && p[i].any())
                x ^= p[i];
        return x;
    }

    std::vector<B> Basis() const {
        std::vector<B> res;
        for (int i = 0; i < N; i++)
            if (p[i].any())
                res.emplace_back(p[i]);
        return res;
    }
};
```


== 矩阵快速幂
定长静态矩阵乘法与快速幂，转置 + 分块延迟取模压常数。

- 按题目修改 `MOD` 与 `N`；要求 `MOD < 2^30`，
  否则 16 组乘积的 `u64` 累加会溢出；
- 用法：输入写进 `a`，设好 `n`，调用 `Pow(k)`，结果在 `b`；
- `Pow(0)` 返回单位矩阵；`b` 每次调用时重新初始化，可重复调用；
- 注意 `Pow` 会破坏 `a`（变为 `a` 的若干次平方）；
- 复杂度 `O(n^3 log k)`；`mul` 先把右操作数转置成按行访问，
  再以 16 列为块累加进 `u64`、块末取一次模；
- 线性递推加速：`m` 阶递推压成 `m x m` 转移矩阵的幂。

```cpp
using u32 = unsigned;
using u64 = uint64_t;
using i64 = int64_t;

namespace MatrixOps {
    constexpr int MOD = 998244353;
    constexpr int N = 200;
    u32 a[N][N], b[N][N];
    int n;

    void mul(const u32 A[N][N], const u32 B[N][N],
             u32 C[N][N]) {
        static u32 bt[N][N];
        for (int i = 0; i < n; i++)
            for (int j = 0; j < n; j++)
                bt[j][i] = B[i][j];
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                u64 res = 0;
                int k = 0;
                for (; k + 15 < n; k += 16) {
                    u64 sum = 0;
                    for (int d = 0; d < 16; d++)
                        sum += u64(A[i][k + d]) * bt[j][k + d];
                    res += sum % MOD;
                }
                u64 sum = 0;
                for (; k < n; k++)
                    sum += u64(A[i][k]) * bt[j][k];
                res += sum % MOD;
                C[i][j] = res % MOD;
            }
        }
    }

    void Pow(i64 y) {
        static u32 t[N][N];
        for (int i = 0; i < n; i++) {
            std::fill(b[i], b[i] + n, 0u);
            b[i][i] = 1;
        }
        while (y) {
            if (y & 1) {
                mul(a, b, t);
                std::memcpy(b, t, sizeof(b));
            }
            y >>= 1;
            if (!y)
                break;
            mul(a, a, t);
            std::memcpy(a, t, sizeof(a));
        }
    }
}
```


= 数据结构
== 并查集 (DSU)
维护无向连通性和连通块大小，`Merge(x, y)` 返回是否真的合并成功。

```cpp
struct DSU {
    std::vector<int> f, sz;

    DSU(int n) : f(n), sz(n, 1) {
        std::iota(f.begin(), f.end(), 0);
    }

    auto Find(int x) {
        while (x != f[x])
            x = f[x] = f[f[x]];
        return x;
    }

    auto Merge(int x, int y) {
        x = Find(x), y = Find(y);
        if (x == y)
            return false;
        if (sz[x] < sz[y])
            std::swap(x, y);
        sz[x] += sz[y];
        f[y] = x;
        return true;
    }

    auto Size(int x) { return sz[Find(x)]; }
};
```


== 树状数组
维护单点加、前缀和、区间和。

- 使用 `1-indexed`；
- `Sum(l, r)` 查询闭区间 `[l, r]`；
- 单次操作复杂度 `O(log n)`。

```cpp
template <typename T>
struct Fenwick {
    int n;
    std::vector<T> a;

    Fenwick(int n) : n(n), a(n + 1) {}

    void Add(int x, T v) {
        for (int i = x; i <= n; i += i & -i)
            a[i] += v;
    }

    auto sum(int x) {
        T res = {};
        for (int i = x; i; i -= i & -i)
            res += a[i];
        return res;
    }

    auto Sum(int l, int r) {
        return sum(r) - sum(l - 1);
    }
};
```


== 线段树
维护单点修改、区间查询。

- 数组下标为 `0..n - 1`；
- `Set(p, x)`、`Get(p)` 操作单点 `p`；
- `Query(l, r)` 查询左闭右开区间 `[l, r)`；
- `SegTree(m, arr)` 使用 `arr[0..m)` 初始化，`arr` 可以是左值或右值。

- 单次操作复杂度 `O(log n)`。

关于 `S` 的约束：

- 存在满足封闭性结合律的 `operator+` 运算；
- 存在单位元 `{}` （具有默认构造函数，且满足和单位元运算后不改变原值）

关于初始序列：

- `arr` 支持随机访问，且至少有 `m` 个元素；
- 若元素类型 ≠ `S`，则必须能赋值给 `S`。

```cpp
template <class S>
struct SegTree {

    int n;
    std::vector<S> tr;

    SegTree(int m, auto&& arr) {
        for (n = 1; n < m; n <<= 1)
            ;
        tr.resize(n << 1);
        for (int i = 0; i < m; i++)
            tr[i + n] = arr[i];
        for (int i = n - 1; i >= 1; i--)
            pull(i);
    }

    void pull(int k) {
        tr[k] = tr[k << 1] + tr[k << 1 | 1];
    }

    void Set(int p, const S& x) {
        p += n;
        tr[p] = x;
        for (p >>= 1; p; p >>= 1)
            pull(p);
    }

    auto Get(int p) { return tr[p + n]; }

    auto Query(int l, int r) {
        l += n, r += n;
        S sml{}, smr{};
        while (l < r) {
            if (l & 1)
                sml = sml + tr[l++];
            if (r & 1)
                smr = tr[--r] + smr;
            l >>= 1;
            r >>= 1;
        }
        return sml + smr;
    }
};
```


`S` 的经典实例——维护最大子段和（Kadane 合并）。
空状态用哨兵 `-1e18` 而 `sum`、`len` 取 0，恰好构成单位元：

```cpp
using i64 = int64_t;

struct Kadane {
    i64 len{};
    i64 sum{}, ans = -1e18;
    i64 pre = -1e18, suf = -1e18;

    Kadane() = default;
    Kadane(i64 v)
        : len(1), sum(v), ans(v), pre(v), suf(v) {}

    friend Kadane operator+(const Kadane& l, const Kadane& r) {
        Kadane res;
        res.len = l.len + r.len;
        res.sum = l.sum + r.sum;
        res.pre = std::max(l.pre, l.sum + r.pre);
        res.suf = std::max(r.suf, l.suf + r.sum);
        res.ans = std::max({l.ans, r.ans, l.suf + r.pre});
        return res;
    }
};
```


== 懒标记线段树
使用非递归的实现方式。

- 数组下标为 `0..n - 1`；
- `Set(p, x)`、`Get(p)` 操作单点 `p`；
- `Update(l, r, f)`、`Query(l, r)` 操作左闭右开区间 `[l, r)`；
- `LazySegTree(m, arr)` 使用 `arr[0..m)` 初始化，`arr` 可以是左值或右值。

- 单次操作复杂度 `O(log n)`。

关于 `F` 的约束：

- 存在满足封闭性的 `operator+=` 运算；
- 存在一个恒等映射 `{}`（默认构造函数）。

关于 `S` 的约束：

- 存在满足封闭性结合律的 `operator+` 运算；
- 存在单位元 `{}` （具有默认构造函数，且满足和单位元运算后不改变原值）
- 存在 `operator*=` 运算满足将映射 `F` 应用于 `S` 返回一个 `S`，并且满足分配律。

关于初始序列：

- `arr` 支持随机访问，且至少有 `m` 个元素；
- 若元素类型 ≠ `S`，则必须能赋值给 `S`。

```cpp
template <class S, class F>
struct LazySegTree {

    int n, h;
    std::vector<S> tr;
    std::vector<F> lz;

    LazySegTree(int m, auto&& arr) {
        for (n = 1; n < m; n <<= 1)
            ;
        h = std::countr_zero((unsigned)n);
        tr.resize(n << 1);
        lz.resize(n);
        for (int i = 0; i < m; i++)
            tr[i + n] = arr[i];
        for (int i = n - 1; i >= 1; i--)
            pull(i);
    }

    void apply(int k, const F& f) {
        tr[k] *= f;
        if (k < n)
            lz[k] += f;
    }

    void pull(int k) {
        tr[k] = tr[k << 1] + tr[k << 1 | 1];
    }

    void push(int k) {
        apply(k << 1, lz[k]);
        apply(k << 1 | 1, lz[k]);
        lz[k] = {};
    }

    void Set(int p, const S& x) {
        p += n;
        for (int i = h; i >= 1; i--)
            push(p >> i);
        tr[p] = x;
        for (int i = 1; i <= h; i++)
            pull(p >> i);
    }

    auto Get(int p) {
        p += n;
        for (int i = h; i >= 1; i--)
            push(p >> i);
        return tr[p];
    }

    void Update(int l, int r, const F& f) {
        l += n, r += n;
        for (int i = h; i >= 1; i--) {
            if ((l & ((1 << i) - 1)) != 0)
                push(l >> i);
            if ((r & ((1 << i) - 1)) != 0)
                push((r - 1) >> i);
        }
        {
            int l_ = l, r_ = r;
            while (l < r) {
                if (l & 1)
                    apply(l++, f);
                if (r & 1)
                    apply(--r, f);
                l >>= 1;
                r >>= 1;
            }
            l = l_;
            r = r_;
        }
        for (int i = 1; i <= h; i++) {
            if ((l & ((1 << i) - 1)) != 0)
                pull(l >> i);
            if ((r & ((1 << i) - 1)) != 0)
                pull((r - 1) >> i);
        }
    }

    auto Query(int l, int r) {
        l += n, r += n;
        for (int i = h; i >= 1; i--) {
            if ((l & ((1 << i) - 1)) != 0)
                push(l >> i);
            if ((r & ((1 << i) - 1)) != 0)
                push((r - 1) >> i);
        }
        S sml{}, smr{};
        while (l < r) {
            if (l & 1)
                sml = sml + tr[l++];
            if (r & 1)
                smr = tr[--r] + smr;
            l >>= 1;
            r >>= 1;
        }
        return sml + smr;
    }
};
```


== 异或 Trie
维护非负整数可重集，支持插入、删除和查询与 `x` 异或的最大值。

- 默认考虑 `[30, 0]` 位；
- 删除前需要保证元素存在；
- 查询前需要保证集合非空；
- 单次操作复杂度均为 `O(31)`。

```cpp
struct XorTrie {
    std::vector<std::array<int, 2>> ch;
    std::vector<int> cnt;
    int tot = 1;

    XorTrie(int n) : ch(n * 32), cnt(n * 32) {}

    void Insert(int x) {
        int u = 1;
        cnt[u]++;
        for (int i = 30; i >= 0; i--) {
            int c = (x >> i) & 1;
            if (not ch[u][c]) {
                ch[u][c] = ++tot;
            }
            u = ch[u][c];
            cnt[u]++;
        }
    }

    void Erase(int x) {
        int u = 1;
        cnt[u]--;
        for (int i = 30; i >= 0; i--) {
            int c = (x >> i) & 1;
            u = ch[u][c];
            cnt[u]--;
        }
    }

    auto Query(int x) {
        int res = 0;
        int u = 1;
        for (int i = 30; i >= 0; i--) {
            int c = (x >> i) & 1;
            int v = ch[u][c ^ 1];
            if (v and cnt[v] > 0) {
                u = v;
                res |= (1 << i);
            } else {
                u = ch[u][c];
            }
        }
        return res;
    }
};
```


== ST 表
维护静态区间查询。

- 查询区间为左闭右开 `[l, r)`；
- 运算需要满足结合律和幂等性，例如 `min`、`max`、`gcd`；
- 预处理复杂度 `O(n log n)`，单次查询 `O(1)`。

//
```cpp
template <class T>
struct SparseTable {
    using Op = std::function<T(const T&, const T&)>;

    int n = 0;
    Op op;
    std::vector<int> lg;
    std::vector<std::vector<T>> st;

    SparseTable() = default;

    SparseTable(const std::vector<T>& a, Op op)
        : op(std::move(op)) {
        Build(a.begin(), a.end());
    }

    SparseTable(auto l, auto r, Op op)
        : op(std::move(op)) {
        Build(l, r);
    }

    void Build(auto l, auto r) {
        n = int(r - l);
        lg.assign(n + 1, 0);
        for (int i = 2; i <= n; i++)
            lg[i] = lg[i >> 1] + 1;
        st.assign(lg[n] + 1, std::vector<T>(n));
        for (int i = 0; i < n; i++)
            st[0][i] = *(l + i);
        for (int k = 1; k < int(st.size()); k++) {
            int len = 1 << k;
            for (int i = 0; i + len <= n; i++) {
                st[k][i] =
                    op(st[k - 1][i],
                       st[k - 1][i + (len >> 1)]);
            }
        }
    }

    T Query(int l, int r) const {
        assert(0 <= l and l < r and r <= n);
        int k = lg[r - l];
        return op(st[k][l], st[k][r - (1 << k)]);
    }
};
```


== 可并堆
`pb_ds` 配对堆，免手写左偏树。

- 需要在 `#define int long long` 之前引入
  `<ext/pb_ds/priority_queue.hpp>`；
- 默认大根堆；需要小根堆时，把别名中的 `std::less<int>` 改为
  `std::greater<int>`；
- `push` 返回 `point_iterator` 句柄，句柄在 `join` 之后仍然有效，
  可用于 `modify(it, v)` 与 `erase(it)`；
- `a.join(b)` 把 `b` 并入 `a` 并清空 `b`，均摊 `O(1)`；
  `pop` 均摊 `O(log n)`；
- 按集合合并时常配 DSU：以 DSU 的 `sz` 决定 `join` 方向，
  堆下标始终用 `Find` 后的代表元。

```cpp
using Heap = __gnu_pbds::priority_queue<
    int, std::less<int>, __gnu_pbds::pairing_heap_tag>;

// Heap h;
// auto it = h.push(x);                 稳定句柄
// h.modify(it, v), h.erase(it);
// a.join(b);                           b 被清空
```


== 势能线段树
本节属于 Trick；Trick 分区建立前暂存于数据结构。

处理不满足结合律、但会让元素快速收敛的区间修改
（区间开方、区间取模等）：额外维护区间最大值，
整段已收敛则直接跳过。

- 模板实现区间开方 + 区间求和（洛谷 P4145）：
  `mx <= 1` 的子树开方不变，整棵剪掉；
- 每个元素开方 `O(log log V)` 次后收敛到 1，
  总复杂度 `O((n + q log n) log log V)` 量级；
- 区间取模变体：改判 `mx < x` 则跳过，叶子执行 `a_i %= x`
  （每次有效取模至少减半，势能同理）；
- 修改必须递归到叶子逐个执行，不能打懒标记——
  剪枝条件是正确性的全部来源。

```cpp
using i64 = int64_t;

struct PotSegTree {
    struct Node {
        i64 sum = 0, mx = 0;
    };

    int n;
    std::vector<Node> tr;

    PotSegTree(auto first, auto last)
        : n(last - first), tr(4 * n) {
        build(first, 1, 0, n - 1);
    }

    void build(auto a, int p, int l, int r) {
        if (l == r) {
            tr[p] = {a[l], a[l]};
            return;
        }
        int mid = (l + r) / 2;
        build(a, 2 * p, l, mid);
        build(a, 2 * p + 1, mid + 1, r);
        pull(p);
    }

    void pull(int p) {
        tr[p].sum = tr[2 * p].sum + tr[2 * p + 1].sum;
        tr[p].mx = std::max(tr[2 * p].mx, tr[2 * p + 1].mx);
    }

    void Sqrt(int l, int r) { sqrt(l, r, 1, 0, n - 1); }

    void sqrt(int ql, int qr, int p, int l, int r) {
        if (qr < l or r < ql or tr[p].mx <= 1)
            return;
        if (l == r) {
            tr[p].sum = tr[p].mx = i64(sqrtl(tr[p].sum));
            return;
        }
        int mid = (l + r) / 2;
        sqrt(ql, qr, 2 * p, l, mid);
        sqrt(ql, qr, 2 * p + 1, mid + 1, r);
        pull(p);
    }

    i64 Query(int l, int r) {
        return query(l, r, 1, 0, n - 1);
    }

    i64 query(int ql, int qr, int p, int l, int r) {
        if (qr < l or r < ql)
            return 0;
        if (ql <= l and r <= qr)
            return tr[p].sum;
        int mid = (l + r) / 2;
        return query(ql, qr, 2 * p, l, mid) +
               query(ql, qr, 2 * p + 1, mid + 1, r);
    }
};
```


== 可持久化权值线段树
主席树：按前缀建版本的权值线段树，两版本相减得到
任意区间的值域信息。

- 值域须先离散化到 `[1, n]`；构造后按原数组顺序逐个 `Add`，
  版本 `i` 对应前缀 `[1, i]`；
- `Kth(l, r, k)`：下标区间 `[l, r]`（1-indexed）第 `k` 小的
  离散化值；`Count(l, r, x, y)`：区间内值落在 `[x, y]` 的个数；
- 单次操作 `O(log n)`；节点数约 `(插入次数) x (log n + 1)`，
  大数据先 `tr.reserve` 防反复扩容；
- 版本 0 是空树（节点 0 自环为空儿子），无需特判。

```cpp
struct HJT {
    struct Node {
        int l = 0, r = 0, cnt = 0;
    };

    int n;
    std::vector<Node> tr;
    std::vector<int> root;

    HJT(int n) : n(n), tr(1), root(1, 0) {}

    void Add(int x) {
        root.push_back(add(root.back(), 1, n, x));
    }

    int add(int v, int l, int r, int x) {
        int u = tr.size();
        tr.push_back(tr[v]);
        tr[u].cnt++;
        if (l == r)
            return u;
        int mid = (l + r) / 2;
        if (x <= mid)
            tr[u].l = add(tr[v].l, l, mid, x);
        else
            tr[u].r = add(tr[v].r, mid + 1, r, x);
        return u;
    }

    int Kth(int ql, int qr, int k) {
        return kth(root[ql - 1], root[qr], 1, n, k);
    }

    int kth(int u, int v, int l, int r, int k) {
        if (l == r)
            return l;
        int mid = (l + r) / 2;
        int res = tr[tr[v].l].cnt - tr[tr[u].l].cnt;
        if (k <= res)
            return kth(tr[u].l, tr[v].l, l, mid, k);
        return kth(tr[u].r, tr[v].r, mid + 1, r, k - res);
    }

    int Count(int ql, int qr, int x, int y) {
        return count(root[ql - 1], root[qr], 1, n, x, y);
    }

    int count(int u, int v, int l, int r, int x, int y) {
        if (x <= l and r <= y)
            return tr[v].cnt - tr[u].cnt;
        int mid = (l + r) / 2;
        int res = 0;
        if (x <= mid)
            res += count(tr[u].l, tr[v].l, l, mid, x, y);
        if (y > mid)
            res += count(tr[u].r, tr[v].r, mid + 1, r, x, y);
        return res;
    }
};
```


= 图论
== 图论通用约束

+ 使用 `vector<vector<int>> adj` 存储点编号为 `1..n` 的无权图；
  有向边只加入一个方向，无向边同时加入两个方向；
+ 使用 `vector<vector<pair<int, int>>> adj` 存储带权图，
  `pair.first` 为终点，`pair.second` 为边权；
+ 使用 `vector<pair<int, int>> es` 存储边，使用
  `vector<array<int, 3>> es` 存储带权边；根据语义也可以命名为
  `uv` 或 `uvw`；
+ 使用 `deg` 存储度数；只使用入度或出度之一时也可使用 `deg`，
  同时使用时分别命名为 `indeg` 和 `outdeg`；
+ 使用 `fa[u]` 表示点 `u` 的父亲节点。

== 单源最短路
适用于非负边权图。

- `adj[u]` 存储 `(v, w)`；
- 默认点编号为 `1..n`；
- 复杂度 `O((n + m) log n)`。

```cpp
using i64 = int64_t;
constexpr i64 INF = 4'000'000'000'000'000'000LL;

auto dijkstra(
    const vector<vector<pair<int, int>>>& adj,
    int n, int s) {
    vector<i64> dis(n + 1, INF);
    vector<bool> vis(n + 1, false);
    priority_queue<pair<i64, int>> pq;
    dis[s] = 0;
    pq.emplace(0, s);
    while (!pq.empty()) {
        auto [_, u] = pq.top();
        pq.pop();
        if (vis[u])
            continue;
        vis[u] = true;
        for (auto [v, w] : adj[u]) {
            if (dis[u] + w < dis[v]) {
                dis[v] = dis[u] + w;
                pq.emplace(-dis[v], v);
            }
        }
    }
    return dis;
}
```


== 分层图最短路
适用于非负边权图上最多使用 `k` 次特殊操作。

`P4568` 的建模方式：

- `dist[u][i]` 表示到达点 `u`，且已经用了 `i` 次免费机会的最小代价；
- 走普通边：`(u, i) -> (v, i)`，边权为 `w`；
- 若 `i < k`，则可以免费走这条边：`(u, i) -> (v, i + 1)`，边权为 `0`；
- 答案为 `min(dist[t][0..k])`。

复杂度 `O((n k + m k) log(n k))`。

```cpp
auto LayeredDijkstra(
    const vector<vector<pair<int, int>>>& adj,
    int n, int s, int k) {
    using i64 = int64_t;
    constexpr i64 INF = 4'000'000'000'000'000'000LL;
    vector dist(n + 1, vector<i64>(k + 1, INF));
    priority_queue<tuple<i64, int, int>> pq;
    dist[s][0] = 0;
    pq.emplace(0, s, 0);
    while (!pq.empty()) {
        auto [d, u, used] = pq.top();
        pq.pop();
        d = -d;
        if (d != dist[u][used])
            continue;
        for (auto [v, w] : adj[u]) {
            if (dist[u][used] + w < dist[v][used]) {
                dist[v][used] = dist[u][used] + w;
                pq.emplace(-dist[v][used], v, used);
            }
            if (used < k and
                dist[u][used] < dist[v][used + 1]) {
                dist[v][used + 1] = dist[u][used];
                pq.emplace(-dist[v][used + 1], v,
                           used + 1);
            }
        }
    }
    return dist;
}
```


== 差分约束
Bellman-Ford 判负环并求一组可行解。

- 约束形如 `x[v] <= x[u] + w`；
- `uvw` 存储 `(u, v, w)`；
- 无解返回空数组。

```cpp
using i64 = int64_t;

auto DifferenceConstraints(
    int n, const vector<array<int, 3>>& uvw) {
    vector<i64> d(n + 1);
    for (int i = 1; i <= n; i++) {
        bool changed = false;
        for (auto [u, v, w] : uvw) {
            if (d[v] > d[u] + w) {
                d[v] = d[u] + w;
                changed = true;
            }
        }
        if (!changed)
            break;
        if (i == n)
            return vector<i64>{};
    }
    return d;
}
```


== 拓扑排序
Kahn 算法。

- 默认点编号 `1..n`；
- 若返回数量小于 `n`，则图中有环；
- 复杂度 `O(n + m)`。

```cpp
auto TopoSort(const vector<vector<int>>& adj,
              int n) {
    vector<int> indeg(n + 1), res;
    queue<int> q;
    for (int u = 1; u <= n; u++)
        for (int v : adj[u])
            indeg[v]++;
    for (int i = 1; i <= n; i++)
        if (!indeg[i])
            q.emplace(i);
    while (!q.empty()) {
        int u = q.front();
        q.pop();
        res.emplace_back(u);
        for (int v : adj[u])
            if (--indeg[v] == 0)
                q.emplace(v);
    }
    return res;
}
```


== 强连通分量 (SCC)
Tarjan 求有向图强连通分量。

- 默认点编号 `1..n`；
- `id[u]` 为 `u` 所在 SCC 编号；
- 复杂度 `O(n + m)`。

```cpp
struct SCC {
    int n, now = 0, cnt = 0;
    vector<vector<int>> adj;
    vector<int> dfn, low, stk, ins, id;

    SCC(int n)
        : n(n), adj(n + 1), dfn(n + 1), low(n + 1),
          ins(n + 1), id(n + 1) {}

    void AddEdge(int u, int v) {
        adj[u].emplace_back(v);
    }

    void tarjan(int u) {
        dfn[u] = low[u] = ++now;
        stk.emplace_back(u);
        ins[u] = true;
        for (int v : adj[u]) {
            if (!dfn[v]) {
                tarjan(v);
                low[u] = min(low[u], low[v]);
            } else if (ins[v]) {
                low[u] = min(low[u], dfn[v]);
            }
        }
        if (dfn[u] == low[u]) {
            cnt++;
            while (true) {
                int x = stk.back();
                stk.pop_back();
                ins[x] = false;
                id[x] = cnt;
                if (x == u)
                    break;
            }
        }
    }

    std::pair<std::vector<int>, int> Work() {
        for (int i = 1; i <= n; i++)
            if (!dfn[i])
                tarjan(i);
        return {id, cnt};
    }
};
```


== 割点
Tarjan 求无向图割点。

- 默认点编号 `1..n`；
- 返回所有割点；
- 复杂度 `O(n + m)`。

```cpp
auto CutVertex(const vector<vector<int>>& adj,
               int n) {
    vector<int> dfn(n + 1), low(n + 1), cut(n + 1),
        fa(n + 1), res;
    int now = 0;
    auto dfs = [&](auto&& self, int u) -> void {
        dfn[u] = low[u] = ++now;
        int child = 0;
        for (int v : adj[u]) {
            if (!dfn[v]) {
                child++;
                fa[v] = u;
                self(self, v);
                low[u] = min(low[u], low[v]);
                if (fa[u] != 0 and low[v] >= dfn[u])
                    cut[u] = true;
            } else if (v != fa[u]) {
                low[u] = min(low[u], dfn[v]);
            }
        }
        if (fa[u] == 0 and child >= 2)
            cut[u] = true;
    };
    for (int i = 1; i <= n; i++)
        if (!dfn[i])
            dfs(dfs, i);
    for (int i = 1; i <= n; i++)
        if (cut[i])
            res.emplace_back(i);
    return res;
}
```


== Dinic 最大流
分层图 + 当前弧优化求最大流，链式前向星扁平存边。

- 默认点编号 `1..n`；
- `AddEdge(u, v, c)` 添加一条容量为 `c` 的有向边，
  返回全局边编号（正反两条成对，`id ^ 1` 即反向边）；
- `Flow(id)` 返回该边的实际流量；
- BFS 在弹出深度不小于 `dep[t]` 的节点时截断：层图到 `t`
  所在层仍然完整，复杂度证明不受影响；
- 一般图复杂度 `O(n^2m)`，二分图等特殊图更快。

```cpp
using i64 = int64_t;

struct Dinic {
    int n;
    vector<int> to, nxt, head, dep, cur, que;
    vector<i64> cap;

    Dinic(int n)
        : n(n), head(n + 1, -1), dep(n + 1), cur(n + 1) {}

    int AddEdge(int u, int v, i64 c) {
        int id = to.size();
        to.push_back(v), nxt.push_back(head[u]);
        cap.push_back(c);
        head[u] = id;
        to.push_back(u), nxt.push_back(head[v]);
        cap.push_back(0);
        head[v] = id + 1;
        return id;
    }

    i64 Flow(int id) const { return cap[id ^ 1]; }

    i64 MaxFlow(int s, int t) {
        i64 flow = 0;
        constexpr i64 INF = numeric_limits<i64>::max() / 4;
        while (bfs(s, t)) {
            copy(head.begin(), head.end(), cur.begin());
            while (i64 f = dfs(s, t, INF))
                flow += f;
        }
        return flow;
    }

    bool bfs(int s, int t) {
        fill(dep.begin(), dep.end(), -1);
        que.clear();
        que.push_back(s);
        dep[s] = 0;
        for (size_t i = 0; i < que.size(); i++) {
            int u = que[i];
            if (dep[t] != -1 and dep[u] >= dep[t])
                break;
            for (int e = head[u]; e != -1; e = nxt[e]) {
                if (cap[e] > 0 and dep[to[e]] == -1) {
                    dep[to[e]] = dep[u] + 1;
                    que.push_back(to[e]);
                }
            }
        }
        return dep[t] != -1;
    }

    i64 dfs(int u, int t, i64 f) {
        if (u == t or f == 0)
            return f;
        for (int& e = cur[u]; e != -1; e = nxt[e]) {
            int v = to[e];
            if (cap[e] <= 0 or dep[v] != dep[u] + 1)
                continue;
            i64 w = dfs(v, t, min(f, cap[e]));
            if (w == 0)
                continue;
            cap[e] -= w;
            cap[e ^ 1] += w;
            return w;
        }
        return 0;
    }
};
```


== 二分图最大匹配
匈牙利算法。

- 左部点 `1..n`，右部点 `1..m`；
- `adj[u]` 存储左部点 `u` 能匹配的右部点；
- 复杂度 `O(nm)`，稀疏图通常够用。

```cpp
auto BipartiteMatching(
    const vector<vector<int>>& adj, int n, int m) {
    vector<int> mt(m + 1), vis(m + 1);
    int ans = 0, stamp = 0;
    auto dfs = [&](auto&& self,
                   int u) -> bool {
        for (int v : adj[u]) {
            if (vis[v] == stamp)
                continue;
            vis[v] = stamp;
            if (!mt[v] or self(self, mt[v])) {
                mt[v] = u;
                return true;
            }
        }
        return false;
    };
    for (int i = 1; i <= n; i++) {
        stamp++;
        ans += dfs(dfs, i);
    }
    return ans;
}
```


== Hopcroft-Karp
二分图最大匹配。

- 左部点 `1..n`，右部点 `1..m`；
- `AddEdge(u, v)` 添加一条左部 `u` 到右部 `v` 的边；
- `matchL[u]` 是左部点 `u` 匹配到的右部点；
- 复杂度 `O(E \sqrt V)`。

```cpp
struct HopcroftKarp {
    int n, m;
    vector<vector<int>> adj;
    vector<int> matchL, matchR, dis;

    HopcroftKarp(int n, int m)
        : n(n), m(m), adj(n + 1), matchL(n + 1),
          matchR(m + 1), dis(n + 1) {}

    void AddEdge(int u, int v) {
        adj[u].emplace_back(v);
    }

    int Work() {
        int ans = 0;
        while (bfs()) {
            for (int u = 1; u <= n; u++)
                if (!matchL[u] and dfs(u))
                    ans++;
        }
        return ans;
    }

    bool bfs() {
        queue<int> q;
        fill(dis.begin(), dis.end(), -1);
        for (int u = 1; u <= n; u++) {
            if (!matchL[u]) {
                dis[u] = 0;
                q.emplace(u);
            }
        }
        bool found = false;
        while (!q.empty()) {
            int u = q.front();
            q.pop();
            for (int v : adj[u]) {
                int x = matchR[v];
                if (!x) {
                    found = true;
                } else if (dis[x] == -1) {
                    dis[x] = dis[u] + 1;
                    q.emplace(x);
                }
            }
        }
        return found;
    }

    bool dfs(int u) {
        for (int v : adj[u]) {
            int x = matchR[v];
            if (!x or (dis[x] == dis[u] + 1 and dfs(x))) {
                matchL[u] = v;
                matchR[v] = u;
                return true;
            }
        }
        dis[u] = -1;
        return false;
    }
};
```

// 参考：https://github.com/hh2048/XCPC/tree/main

== 无向图欧拉回路
参考 hh2048/XCPC 的无向图版本，改写为保留边号的非递归
Hierholzer 算法。

- 默认点编号 `1..n`，`es[i] = (u, v)`，支持重边与自环；
- 存在奇度点时返回空值，否则返回各连通块回路拼接后的有向边编号：
  `e / 2` 是原边编号，`e & 1` 表示方向与 `(u, v)` 相反；
- CF2192E 中输出所有满足 `e & 1` 的 `e / 2 + 1`；
- 复杂度 `O(n + m)`，空间复杂度 `O(n + m)`。

```cpp
auto EulerCircuit(
    int n, const vector<pair<int, int>>& es)
    -> optional<vector<int>> {
    int m = es.size();
    vector<vector<int>> adj(n + 1);
    vector<int> deg(n + 1);
    for (int i = 0; i < m; i++) {
        auto [u, v] = es[i];
        adj[u].emplace_back(2 * i);
        adj[v].emplace_back(2 * i + 1);
        deg[u]++, deg[v]++;
    }
    for (int u = 1; u <= n; u++)
        if (deg[u] & 1)
            return nullopt;

    vector<int> tour;
    vector<char> used(m);
    vector<pair<int, int>> stk;
    tour.reserve(m);
    for (int s = 1; s <= n; s++) {
        if (adj[s].empty())
            continue;
        stk = {{s, -1}};
        while (!stk.empty()) {
            int u = stk.back().first;
            while (!adj[u].empty() and
                   used[adj[u].back() / 2])
                adj[u].pop_back();
            if (adj[u].empty()) {
                int e = stk.back().second;
                stk.pop_back();
                if (e != -1)
                    tour.emplace_back(e);
            } else {
                int e = adj[u].back();
                adj[u].pop_back();
                auto [x, y] = es[e / 2];
                int v = e & 1 ? x : y;
                used[e / 2] = true;
                stk.emplace_back(v, e);
            }
        }
    }
    reverse(tour.begin(), tour.end());
    return tour;
}
```


= 树上问题
== LCA
倍增求树上最近公共祖先。

- 默认点编号 `1..n`；
- `adj` 是无向树；
- `Get(u, v)` 返回 `u` 和 `v` 的 LCA；
- `Dis(u, v)` 返回 `u` 和 `v` 的距离；
- `Kth(u, v, k)` 返回从 `u` 到 `v` 路径上的第 `k` 个点，`k` 从 `0` 开始；
- `Component(u, v)` 返回删掉点 `u` 后 `v` 所在连通块的大小，要求 `u` 和 `v` 相邻；
- 预处理复杂度 `O(n log n)`，单次查询 `O(log n)`。

```cpp
struct LCA {
    int n, LOG;
    vector<int> dep, siz;
    vector<vector<int>> up;

    LCA(const vector<vector<int>>& adj, int root = 1) {
        n = adj.size() - 1;
        LOG = std::bit_width((unsigned)n);
        dep.assign(n + 1, 0);
        siz.assign(n + 1, 1);
        up.assign(LOG, vector<int>(n + 1, root));

        auto dfs = [&](auto&& self, int u,
                       int p) -> void {
            up[0][u] = p;
            for (int i = 1; i < LOG; i++)
                up[i][u] = up[i - 1][up[i - 1][u]];
            for (int v : adj[u]) {
                if (v == p)
                    continue;
                dep[v] = dep[u] + 1;
                self(self, v, u);
                siz[u] += siz[v];
            }
        };
        dfs(dfs, root, root);
    }

    int Get(int u, int v) const {
        if (dep[u] < dep[v])
            swap(u, v);
        u = jump(u, dep[u] - dep[v]);
        if (u == v)
            return u;
        for (int i = LOG - 1; i >= 0; i--) {
            if (up[i][u] != up[i][v]) {
                u = up[i][u];
                v = up[i][v];
            }
        }
        return up[0][u];
    }

    int Dis(int u, int v) const {
        int g = Get(u, v);
        return dep[u] + dep[v] - 2 * dep[g];
    }

    int Kth(int u, int v, int k) const {
        int g = Get(u, v);
        int du = dep[u] - dep[g];
        int d = du + dep[v] - dep[g];
        if (k <= du)
            return jump(u, k);
        return jump(v, d - k);
    }

    int Component(int u, int v) const {
        if (up[0][v] == u)
            return siz[v];
        return n - siz[u];
    }

    int jump(int u, int k) const {
        for (int i = 0; i < LOG; i++)
            if (k >> i & 1)
                u = up[i][u];
        return u;
    }
};
```


== 树上差分
对树上路径做批量加法，再一次 DFS 汇总。

- 默认点编号 `1..n`；
- `AddVertexPath(u, v, w)` 给路径上的点加 `w`；
- `AddEdgePath(u, v, w)` 给路径上的边加 `w`；
- `Work()` 返回汇总后的差分值。对于边差分，边权存放在子节点上。

```cpp
using i64 = int64_t;

struct TreeDifference {
    int n, LOG;
    vector<vector<int>> adj, up;
    vector<int> dep;
    vector<i64> diff;

    TreeDifference(const vector<vector<int>>& adj,
                   int root = 1)
        : n(adj.size() - 1), adj(adj),
          LOG(std::bit_width((unsigned)n)),
          up(LOG, vector<int>(n + 1, root)),
          dep(n + 1), diff(n + 1) {
        auto dfs = [&](auto&& self, int u,
                       int p) -> void {
            up[0][u] = p;
            for (int i = 1; i < LOG; i++)
                up[i][u] = up[i - 1][up[i - 1][u]];
            for (int v : adj[u]) {
                if (v == p)
                    continue;
                dep[v] = dep[u] + 1;
                self(self, v, u);
            }
        };
        dfs(dfs, root, root);
    }

    void AddVertexPath(int u, int v,
                       i64 w = 1) {
        int g = lca(u, v);
        diff[u] += w;
        diff[v] += w;
        diff[g] -= w;
        if (up[0][g] != g)
            diff[up[0][g]] -= w;
    }

    void AddEdgePath(int u, int v,
                     i64 w = 1) {
        int g = lca(u, v);
        diff[u] += w;
        diff[v] += w;
        diff[g] -= 2 * w;
    }

    vector<i64> Work(int root = 1) {
        auto res = diff;
        auto dfs = [&](auto&& self, int u,
                       int p) -> void {
            for (int v : adj[u]) {
                if (v == p)
                    continue;
                self(self, v, u);
                res[u] += res[v];
            }
        };
        dfs(dfs, root, root);
        return res;
    }

    int jump(int u, int k) const {
        for (int i = 0; i < LOG; i++)
            if (k >> i & 1)
                u = up[i][u];
        return u;
    }

    int lca(int u, int v) const {
        if (dep[u] < dep[v])
            swap(u, v);
        u = jump(u, dep[u] - dep[v]);
        if (u == v)
            return u;
        for (int i = LOG - 1; i >= 0; i--) {
            if (up[i][u] != up[i][v]) {
                u = up[i][u];
                v = up[i][v];
            }
        }
        return up[0][u];
    }
};
```


== Kruskal 重构树
把"按边权阈值连通"转成树上问题：按序加边，每次合并
新建内部节点记录边权，叶子 `1..n` 是原图点。

- 传入的边序自己定：按 `w` 升序建树，两点 LCA 的 `val`
  是路径最大边权的最小值；按降序建树则是
  路径最小边权的最大值（NOIP 货车运输）；
- 内部节点沿根方向 `val` 单调，"与 `u` 在阈值 `w` 内连通的
  点集"是 `u` 某个祖先的整棵子树，可配倍增在祖先链上二分；
- 节点总数至多 `2n - 1`；图不连通时是森林，
  查询前用 `Find` 判连通；
- 两点瓶颈查询：配本章 LCA 模板在重构树上求
  `val[lca(u, v)]`。

```cpp
struct KruskalTree {
    int n, tot;
    std::vector<int> f, val;
    std::vector<std::array<int, 2>> son;

    // es 中每条边为 {w, u, v}，按调用方给定的顺序依次合并
    KruskalTree(int n, const std::vector<std::array<int, 3>>& es)
        : n(n), tot(n), f(2 * n), val(2 * n), son(2 * n) {
        std::iota(f.begin(), f.end(), 0);
        for (auto [w, u, v] : es) {
            int x = Find(u), y = Find(v);
            if (x == y)
                continue;
            ++tot;
            val[tot] = w;
            son[tot] = {x, y};
            f[x] = f[y] = tot;
        }
    }

    int Find(int x) {
        while (x != f[x])
            x = f[x] = f[f[x]];
        return x;
    }
};
```


= 字符串
== KMP
求前缀函数，支持模式串匹配。

- `Kmp(s)[i]` 表示 `s[0..i)` 的 border 长度；
- 匹配复杂度 `O(n + m)`。

```cpp
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


= 多项式与卷积
== FFT
复数 FFT 求整数多项式卷积。

- 适合普通整数卷积；
- 返回长度为 `a.size() + b.size() - 1` 的结果；
- 复杂度 `O(n log n)`；
- 依赖 `double` 精度：需保证 `n * max|a| * max|b|`
  不超过约 `1e15`，更大范围改用拆系数或 NTT。

```cpp
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
```
