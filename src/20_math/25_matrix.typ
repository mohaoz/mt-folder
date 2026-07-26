#import "../../template.typ": snippet, web-only

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

#let matrix = ```cpp
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

#snippet(matrix, id: "matrix")
