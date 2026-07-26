#import "../../template.typ": snippet, web-only

#web-only[

== ModInt
固定模数整数，支持四则运算、输入输出和比较。

- `ModInt<P>` 使用 `unsigned` 模数；
- 除法要求除数可逆；
- 乘法对 `u64` 模数使用长双精度近似规避溢出。
]

#let modint = ```cpp
using u32 = unsigned;
using i64 = int64_t;
using u64 = uint64_t;

template <class T>
constexpr auto power(T a, u64 b, T res = 1) {
    for (; b != 0; b /= 2, a *= a) {
        if (b & 1) {
            res *= a;
        }
    }
    return res;
}

template <u32 P>
constexpr auto mulMod(u32 a, u32 b) {
    return u32(u64(a) * b % P);
}

template <u64 P>
constexpr auto mulMod(u64 a, u64 b) {
    u64 res =
        a * b - u64(1.L * a * b / P - 0.5L) * P;
    res %= P;
    return res;
}

constexpr auto safeMod(i64 x, i64 m) {
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

template <class U, U P>
struct ModIntBase {
    static_assert(std::is_unsigned<U>::value);

    constexpr ModIntBase() : x(0) {}
    template <class T, std::enable_if_t<std::is_unsigned<T>::value,
                                       int> = 0>
    constexpr ModIntBase(T x_) : x(x_ % mod()) {}
    template <class T, std::enable_if_t<std::is_signed<T>::value,
                                       int> = 0>
    constexpr ModIntBase(T x_) {
        using S = std::make_signed_t<U>;
        S v = x_ % S(mod());
        if (v < 0) {
            v += mod();
        }
        x = v;
    }

    constexpr static auto mod() { return P; }

    constexpr auto val() const { return x; }

    constexpr auto operator-() const {
        ModIntBase res;
        res.x = (x == 0 ? 0 : mod() - x);
        return res;
    }

    constexpr auto inv() const {
        return power(*this, mod() - 2);
    }

    constexpr auto&
    operator*=(const ModIntBase& rhs) & {
        x = mulMod<mod()>(x, rhs.val());
        return *this;
    }
    constexpr auto&
    operator+=(const ModIntBase& rhs) & {
        x += rhs.val();
        if (x >= mod()) {
            x -= mod();
        }
        return *this;
    }
    constexpr auto&
    operator-=(const ModIntBase& rhs) & {
        x -= rhs.val();
        if (x >= mod()) {
            x += mod();
        }
        return *this;
    }
    constexpr auto&
    operator/=(const ModIntBase& rhs) & {
        return *this *= rhs.inv();
    }

    friend constexpr auto
    operator*(ModIntBase lhs,
              const ModIntBase& rhs) {
        lhs *= rhs;
        return lhs;
    }
    friend constexpr auto
    operator+(ModIntBase lhs,
              const ModIntBase& rhs) {
        lhs += rhs;
        return lhs;
    }
    friend constexpr auto
    operator-(ModIntBase lhs,
              const ModIntBase& rhs) {
        lhs -= rhs;
        return lhs;
    }
    friend constexpr auto
    operator/(ModIntBase lhs,
              const ModIntBase& rhs) {
        lhs /= rhs;
        return lhs;
    }

    friend constexpr auto&
    operator>>(std::istream& is, ModIntBase& a) {
        i64 i;
        is >> i;
        a = i;
        return is;
    }
    friend constexpr auto&
    operator<<(std::ostream& os,
               const ModIntBase& a) {
        return os << a.val();
    }

    friend constexpr bool
    operator==(const ModIntBase& lhs,
               const ModIntBase& rhs) {
        return lhs.val() == rhs.val();
    }
    friend constexpr bool
    operator!=(const ModIntBase& lhs,
               const ModIntBase& rhs) {
        return !(lhs == rhs);
    }
    friend constexpr bool
    operator<(const ModIntBase& lhs,
              const ModIntBase& rhs) {
        return lhs.val() < rhs.val();
    }
    friend constexpr bool
    operator>(const ModIntBase& lhs,
              const ModIntBase& rhs) {
        return rhs < lhs;
    }
    friend constexpr bool
    operator<=(const ModIntBase& lhs,
               const ModIntBase& rhs) {
        return !(rhs < lhs);
    }
    friend constexpr bool
    operator>=(const ModIntBase& lhs,
               const ModIntBase& rhs) {
        return !(lhs < rhs);
    }

    U x;
};

template <u32 P>
using ModInt = ModIntBase<u32, P>;
template <u64 P>
using ModInt64 = ModIntBase<u64, P>;
```

// 这是有意的输出差异：ModInt 只进入 HTML，不进入 PDF。
#snippet(modint, targets: ("web",))
