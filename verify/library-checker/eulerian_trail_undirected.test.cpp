// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/eulerian_trail_undirected

#include <mtf_verify.hpp>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    int test_count;
    std::cin >> test_count;
    while (test_count--) {
        int n, m;
        std::cin >> n >> m;
        std::vector<std::pair<int, int>> es(m);
        std::vector<int> deg(n + 1);
        for (int edge = 0; edge < m; ++edge) {
            int u, v;
            std::cin >> u >> v;
            es[edge] = {u + 1, v + 1};
            deg[u + 1]++;
            deg[v + 1]++;
        }

        std::vector<int> odd;
        for (int u = 1; u <= n; ++u)
            if (deg[u] & 1)
                odd.push_back(u);
        if (odd.size() > 2) {
            std::cout << "No\n";
            continue;
        }
        if (m == 0) {
            std::cout << "Yes\n0\n\n";
            continue;
        }

        int extra = -1;
        if (odd.size() == 2) {
            extra = es.size();
            es.emplace_back(odd[0], odd[1]);
        }
        auto tour = mtf::EulerCircuit(n, es);
        auto from = [&](int e) {
            auto [u, v] = es[e / 2];
            return e & 1 ? v : u;
        };
        auto to = [&](int e) {
            auto [u, v] = es[e / 2];
            return e & 1 ? u : v;
        };
        bool connected = bool(tour);
        for (int i = 1; connected and i < int(tour->size()); ++i)
            connected = to((*tour)[i - 1]) == from((*tour)[i]);
        if (!connected) {
            std::cout << "No\n";
            continue;
        }

        int start = 0;
        if (extra != -1) {
            while ((*tour)[start] / 2 != extra)
                ++start;
            start++;
        }
        auto get = [&](int index) {
            return (*tour)[(start + index) % tour->size()];
        };

        std::cout << "Yes\n" << from(get(0)) - 1;
        for (int i = 0; i < m; ++i)
            std::cout << ' ' << to(get(i)) - 1;
        std::cout << '\n';
        for (int i = 0; i < m; ++i) {
            if (i)
                std::cout << ' ';
            std::cout << get(i) / 2;
        }
        std::cout << '\n';
    }
}
