#import "../../template.typ": snippet, web-only

== 高维前缀和 (SOS DP)
就地计算所有集合的子集和 / 超集和，逐位转移。

- 复杂度 `O(n 2^n)`（逐集合枚举子集是 `3^n`）；
- `f.size()` 必须是 2 的幂；变换按位独立，位枚举顺序任意；
- `inverse = true` 做逆变换（把 `+=` 换成 `-=`），与正变换互逆；
- AND 卷积：两数组分别做超集和，逐点相乘，再做一次逆超集和；
  OR 卷积同理换成子集和；
- 也可对某一维只做部分位，处理"固定若干位、其余任意"的统计。

#let sos-dp = ```cpp
template <class T>
void SubsetSum(std::vector<T>& f, bool inverse = false) {
    int n = __builtin_ctzll(f.size());
    for (int i = 0; i < n; i++)
        for (int s = 0; s < (int)f.size(); s++)
            if (s >> i & 1) {
                if (inverse)
                    f[s] -= f[s ^ 1 << i];
                else
                    f[s] += f[s ^ 1 << i];
            }
}

template <class T>
void SupersetSum(std::vector<T>& f, bool inverse = false) {
    int n = __builtin_ctzll(f.size());
    for (int i = 0; i < n; i++)
        for (int s = 0; s < (int)f.size(); s++)
            if (not(s >> i & 1)) {
                if (inverse)
                    f[s] -= f[s | 1 << i];
                else
                    f[s] += f[s | 1 << i];
            }
}
```

#snippet(sos-dp, id: "sos-dp")
