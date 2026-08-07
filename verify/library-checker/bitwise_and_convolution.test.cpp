// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/bitwise_and_convolution

#include <mtf_verify.hpp>

using Z = mtf::ModInt<998244353>;

bool VerifyBitmaskEnumerations() {
    constexpr int MAX_N = 8;
    for (int n = 0; n <= MAX_N; n++) {
        int ALL = (1LL << n) - 1;
        for (int S = 0; S <= ALL; S++) {
            std::vector<int> seen(ALL + 1);

            // 非空子集
            for (int T = S; T; T = (T - 1) & S)
                seen[T]++;
            for (int T = 0; T <= ALL; T++)
                if (seen[T] != (T != 0 && (T & S) == T))
                    return false;

            // 非空真子集
            std::fill(seen.begin(), seen.end(), 0);
            for (int T = (S - 1) & S; T; T = (T - 1) & S)
                seen[T]++;
            for (int T = 0; T <= ALL; T++)
                if (seen[T] != (T != 0 && T != S && (T & S) == T))
                    return false;

            // 集合中的元素
            std::vector<int> seen_bits(n);
            for (int T = S; T; T &= T - 1) {
                int i = __builtin_ctzll(T);
                seen_bits[i]++;
            }
            for (int i = 0; i < n; i++)
                if (seen_bits[i] != (S >> i & 1))
                    return false;

            // 有序二分：A 和 B 都非空
            std::fill(seen.begin(), seen.end(), 0);
            for (int A = (S - 1) & S; A; A = (A - 1) & S) {
                int B = S ^ A;
                if ((A & B) || (A | B) != S || B == 0)
                    return false;
                seen[A]++;
            }
            for (int A = 0; A <= ALL; A++)
                if (seen[A] != (A != 0 && A != S && (A & S) == A))
                    return false;

            // 无序二分：强制最低位元素属于 A
            int partitions = 0;
            int bit = S & -S;
            for (int A = (S - 1) & S; A; A = (A - 1) & S) {
                if (!(A & bit))
                    continue;
                int B = S ^ A;
                if ((A & B) || (A | B) != S || B == 0)
                    return false;
                partitions++;
            }
            int bits = __builtin_popcount(S);
            int expected_partitions = bits < 2 ? 0 : (1 << (bits - 1)) - 1;
            if (partitions != expected_partitions)
                return false;

            // 与 S 不相交的非空集合
            std::fill(seen.begin(), seen.end(), 0);
            int rest = ALL ^ S;
            for (int T = rest; T; T = (T - 1) & rest)
                seen[T]++;
            for (int T = 0; T <= ALL; T++)
                if (seen[T] != (T != 0 && (T & S) == 0))
                    return false;

            // 超集
            std::fill(seen.begin(), seen.end(), 0);
            for (int T = S;; T = (T + 1) | S) {
                seen[T]++;
                if (T == ALL)
                    break;
            }
            for (int T = 0; T <= ALL; T++)
                if (seen[T] != ((T & S) == S))
                    return false;
        }

        // 固定 popcount（Gosper）
        for (int k = 0; k <= n; k++) {
            std::vector<int> seen(ALL + 1);
            if (k == 0) {
                int S = 0;
                seen[S]++;
            } else {
                for (int S = (1LL << k) - 1; S < 1LL << n;) {
                    seen[S]++;
                    int low = S & -S;
                    int nxt = S + low;
                    if (nxt >= 1LL << n)
                        break;
                    S = nxt | (((nxt ^ S) >> 2) / low);
                }
            }
            for (int S = 0; S <= ALL; S++)
                if (seen[S] != (__builtin_popcount(S) == k))
                    return false;
        }
    }
    return true;
}

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int n;
    std::cin >> n;
    const int size = 1 << n;
    if (!VerifyBitmaskEnumerations())
        return 1;

    std::vector<Z> a(size), b(size);
    for (auto& x : a)
        std::cin >> x;
    for (auto& x : b)
        std::cin >> x;

    // 路径一：AND 卷积 = 超集 Zeta + 逐点乘 + 超集 Möbius。
    auto superset_a = a;
    auto superset_b = b;
    mtf::SupersetZeta(superset_a, n);
    mtf::SupersetZeta(superset_b, n);
    for (int i = 0; i < size; ++i)
        superset_a[i] *= superset_b[i];
    mtf::SupersetMobius(superset_a, n);

    // 路径二：下标取补后，AND 卷积等价为 OR 卷积，
    // 用子集 Zeta / Möbius 独立算一次并与路径一互验。
    int ALL = size - 1;
    std::vector<Z> subset_a(size), subset_b(size);
    for (int S = 0; S < size; S++) {
        subset_a[ALL ^ S] = a[S];
        subset_b[ALL ^ S] = b[S];
    }
    mtf::SubsetZeta(subset_a, n);
    mtf::SubsetZeta(subset_b, n);
    for (int S = 0; S < size; S++)
        subset_a[S] *= subset_b[S];
    mtf::SubsetMobius(subset_a, n);

    for (int S = 0; S < size; S++)
        if (superset_a[S] != subset_a[ALL ^ S])
            return 1;

    for (int i = 0; i < size; ++i)
        std::cout << superset_a[i] << " \n"[i == size - 1];
}
