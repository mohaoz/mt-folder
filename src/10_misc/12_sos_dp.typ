#import "../../template.typ": snippet

== Bitmask 集合枚举

默认 $n <= 30$，用 `int` 的低 $n$ 位表示集合；需要更大位宽时把集合变量统一改为 `i64 / u64`。

=== `<bit>` 与 GNU builtin

C++20 的 `<bit>` 接口只接受无符号整数。默认 `int` 位宽时把参数转为
`unsigned`；使用 `u64` 时直接传入 `u64`，不再区分 builtin 的普通版与
`ll` 版。

- `std::popcount((unsigned)x)` 对应 `__builtin_popcount(x)`；
- `std::countr_zero((unsigned)x)` 对应 `__builtin_ctz(x)`；
- `std::countl_zero((unsigned)x)` 对应 `__builtin_clz(x)`；
- `std::bit_width((unsigned)x) - 1` 对应 `__lg(x)`，要求 $x > 0$；
- `std::has_single_bit((unsigned)x)` 判断是否为 2 的幂；
- `std::bit_floor((unsigned)x)` 和 `std::bit_ceil((unsigned)x)` 分别求不超过、
  不小于 $x$ 的 $2$ 的幂。

=== 基础操作

```cpp
int ALL = (1LL << n) - 1;

S & -S;       // lowbit
S & (S - 1);  // 删除最低位的 1
```

=== 子集 / 真子集

枚举 $S$ 的所有非空子集：

```cpp
for (int T = S; T; T = (T - 1) & S) {
}
```

枚举 $S$ 的所有非空真子集：

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

枚举有序二分 $(A, B)$：

```cpp
for (int A = (S - 1) & S; A; A = (A - 1) & S) {
    int B = S ^ A;
}
```

无序二分去重：固定 $S$ 的最低位元素属于 $A$。

```cpp
int bit = S & -S;

for (int A = (S - 1) & S; A; A = (A - 1) & S) {
    if (!(A & bit))
        continue;

    int B = S ^ A;
}
```

=== 超集 / 不相交集合

枚举与 $S$ 不相交的所有非空集合：

```cpp
int rest = ALL ^ S;

for (int T = rest; T; T = (T - 1) & rest) {
}
```

枚举 $S$ 的所有超集（包含 $S$ 和 `ALL`）：

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

- 枚举一个 $S$ 的所有子集：$O(2^("popcount"(S)))$；
- 枚举所有 $S$ 及其子集：$O(3^n)$；
- 固定 $"popcount"(S) = k$：$O(binom(n, k))$。

```cpp
for (int S = 0; S < 1LL << n; S++)
    for (int T = S; T; T = (T - 1) & S) {
    }
```

上述双重枚举的总复杂度为 $O(3^n)$。

=== 坑点

- `__builtin_ctz(0)` 与 `__builtin_ctzll(0)` 未定义；
  `std::countr_zero(0u)` 则返回参数类型的位数；
- 只有 $T subset.eq S$ 时，`S ^ T` 才等于 $S without T$；
- 使用 `1LL << n`，不要写 `1 << n`；
- $n >= 31$ 时改用 `i64 / u64`；`i64` 仍要求 $n < 63$；
- SOS DP 必须先枚举位，再枚举状态；
- Gosper 需要单独处理 $k = 0$。

== SOS DP

对大小为 `1LL << n` 的数组原地做变换，只保留四个现场常用操作：

- 子集 Zeta：$f[S] = sum_(T subset.eq S) a[T]$；
- 子集 Möbius：子集 Zeta 的逆变换；
- 超集 Zeta：$f[S] = sum_(T supset.eq S) a[T]$；
- 超集 Möbius：超集 Zeta 的逆变换。

#let sos-dp = ```cpp
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

#snippet(sos-dp, id: "sos-dp")

朴素地对所有 $S$ 枚举子集是 $O(3^n)$，SOS DP 是 $O(n dot 2^n)$。
