// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/matrix_rank_mod_2

#include <mtf_verify.hpp>

template <int W>
int MatrixRank(int n, int m) {
    mtf::BitsetLinearBasis<W> basis;

    if (m <= n) {
        for (int i = 0; i < n; i++) {
            std::string s;
            std::cin >> s;
            std::bitset<W> row(s);
            basis.Insert(row);
        }
    } else {
        std::vector<std::string> a(n);
        for (auto& row : a)
            std::cin >> row;
        for (int j = 0; j < m; j++) {
            std::bitset<W> column;
            for (int i = 0; i < n; i++)
                column[i] = a[i][j] == '1';
            basis.Insert(column);
        }
    }
    return basis.rank;
}

template <int W = 1>
int Dispatch(int n, int m) {
    if (std::min(n, m) <= W)
        return MatrixRank<W>(n, m);
    if constexpr (W < 4096)
        return Dispatch<W * 2>(n, m);
    return -1;
}

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int n, m;
    std::cin >> n >> m;
    if (n == 0 || m == 0) {
        std::cout << 0 << '\n';
        return 0;
    }

    int rank = Dispatch(n, m);
    if (rank < 0)
        return 1;
    std::cout << rank << '\n';
}
