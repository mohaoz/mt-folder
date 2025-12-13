#pragma once

#include <chrono>
#include <functional>

using u64 = unsigned long long;

// ANCHOR: hash
struct custom_hash {
    static u64 splitmix64(u64 x) {
        x += 0x9e3779b97f4a7c15;
        x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9;
        x = (x ^ (x >> 27)) * 0x94d049bb133111eb;
        return x ^ (x >> 31);
    }

    u64 operator()(u64 x) const {
        static const u64 SEED =
            std::chrono::high_resolution_clock::now().time_since_epoch().count();
        return splitmix64(x + SEED);
    }
};
// ANCHOR_END: hash

inline void func() {
    // ANCHOR: binary
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
    // ANCHOR_END: binary
    std::vector adj(114, std::vector<int>(514));
    // ANCHOR: recu
    // C++23
    auto dfs1 = [&](this auto &&self, int x, int p) -> void {
        for (auto y : adj[x]) {
            if (y == p)
                continue;
            self(y, x);
        }
    };
    // C++17
    std::function<void(int, int)> dfs2 = [&](int x, int p) {
        for (auto y : adj[x]) {
            if (y == p)
                continue;
            dfs2(y, x);
        }
    };
    // ANCHOR_END: recu
}
