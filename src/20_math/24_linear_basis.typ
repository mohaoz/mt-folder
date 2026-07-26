#import "../../template.typ": snippet, web-only

== 线性基
维护异或线性空间。

- 默认处理 `u64`，最高位为 `63`；
- `Insert(x)` 返回 `x` 是否使秩增加；
- `Contains(x)` 判断 `x` 能否由当前线性基异或得到；
- `MaxXor(x)` 返回 `x` 与线性空间中某个元素异或后的最大值。

#let linear-basis = ```cpp
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

#snippet(linear-basis)
