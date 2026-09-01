#import "../../template.typ": snippet, web-only

== 线性递推
使用特征多项式取模求常系数线性递推的第 `n` 项及其前缀和。

- 长度为 `k` 的 `f` 给出 `f[0..k)`，`b` 定义
  `f[n] = b[0] f[n - 1] + ... + b[k - 1] f[n - k]`；
- `LinearRec<MOD>::Get(f, b, n)` 求齐次递推的 `f[n]`；
- `LinearRec<MOD>::Affine(f, b, C, n)` 处理右侧额外加常数 `C` 的递推，
  返回 `{f[n], f[0] + ... + f[n]}`；
- 两个接口均要求 `n >= 0`、`f.size() >= b.size() > 0`；
- `MOD` 必须为正，输入和返回值均会归一化到 `[0, MOD)`；
- 时间复杂度 `O(k^2 log n)`，空间复杂度 `O(k)`。

#let linear-recurrence = ```cpp
template <int MOD>
struct LinearRec {
    using i64 = int64_t;

    static i64 norm(i64 x) {
        x %= MOD;
        if (x < 0)
            x += MOD;
        return x;
    }

    // b -> (1+b0, b1-b0, ..., -b[k-1])
    static auto lift(const std::vector<i64>& b) {
        int k = b.size();
        std::vector<i64> c(k + 1);
        c[0] = norm(1 + b[0]);
        for (int i = 1; i < k; i++)
            c[i] = norm(b[i] - b[i - 1]);
        c[k] = norm(-b[k - 1]);
        return c;
    }

    static auto mul(const std::vector<i64>& a,
                    const std::vector<i64>& b,
                    const std::vector<i64>& coef) {
        int k = coef.size();
        std::vector<i64> c(2 * k - 1);

        for (int i = 0; i < k; i++)
            for (int j = 0; j < k; j++)
                c[i + j] =
                    (c[i + j] + a[i] * b[j]) % MOD;

        for (int i = 2 * k - 2; i >= k; i--)
            for (int j = 0; j < k; j++)
                c[i - j - 1] =
                    (c[i - j - 1] + c[i] * coef[j]) % MOD;

        c.resize(k);
        return c;
    }

    // f[n] = b[0] f[n-1] + ... + b[k-1] f[n-k]
    static i64 Get(const std::vector<i64>& f,
                   const std::vector<i64>& b,
                   i64 n) {
        int k = b.size();
        assert(n >= 0 and k and f.size() >= b.size());

        std::vector<i64> coef(k);
        for (int i = 0; i < k; i++)
            coef[i] = norm(b[i]);

        if (n < k)
            return norm(f[n]);

        std::vector<i64> res(k), x(k);
        res[0] = 1;

        if (k == 1)
            x[0] = coef[0];
        else
            x[1] = 1;

        while (n) {
            if (n & 1)
                res = mul(res, x, coef);
            x = mul(x, x, coef);
            n >>= 1;
        }

        i64 ans = 0;
        for (int i = 0; i < k; i++)
            ans = (ans + res[i] * norm(f[i])) % MOD;
        return ans;
    }

    // f[n] = C + b[0] f[n-1] + ... + b[k-1] f[n-k]
    // 返回 {f[n], f[0] + ... + f[n]}
    static std::pair<i64, i64> Affine(
        const std::vector<i64>& f,
        const std::vector<i64>& b,
        i64 C, i64 n) {

        int k = b.size();
        assert(n >= 0 and k and f.size() >= b.size());

        std::vector<i64> a(k), coef(k);
        for (int i = 0; i < k; i++) {
            a[i] = norm(f[i]);
            coef[i] = norm(b[i]);
        }
        C = norm(C);

        auto append = [&]() {
            int i = a.size();
            i64 x = C;
            for (int j = 0; j < k; j++)
                x = (x + coef[j] * a[i - 1 - j]) % MOD;
            a.push_back(x);
        };

        // f 的 k+1 阶齐次递推
        append();
        auto fb = lift(coef);
        std::vector<i64> fi(a.begin(), a.end());

        // 前缀和需要 k+2 个初值
        append();
        auto sb = lift(fb);

        std::vector<i64> s(k + 2);
        s[0] = a[0];
        for (int i = 1; i <= k + 1; i++)
            s[i] = (s[i - 1] + a[i]) % MOD;

        return {
            Get(fi, fb, n),
            Get(s, sb, n)
        };
    }
};
```

#snippet(linear-recurrence)
