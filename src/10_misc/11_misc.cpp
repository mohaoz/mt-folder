// CIALLO_MD
// # 杂项
// ## 约定
// 
// 1. C++ 版本：
//    1. 最低支持版本：`c++17`；
//    1. 默认版本：`gnu++23`；
// 2. 格式：
//    1. 缩进宽度为 4 个空格；
//    2. 大括号换行；
//    3. 一元运算符不空格，其他运算符空一格；
// 3. 命名：
//    1. 遵循 `GoLang` 的命名规范；
// 4. 其他：
//    1. 使用邻接表存图；
//    2. 使用 `0-indexed` 的左闭右闭区间；
//    3. 使用解绑同步流的 `std::cin` 和 `std::cout` 输入输出；
//    4. 使用 `using namespace std;`，非必要不使用 `#define int long long`；
//    5. 使用局部变量而非全局变量，局部 `lambda` 而非全局函数；
//    6. 使用 `emplace` 而非 `push`，使用 `contains` 而非 `count`；
//    7. 若键值较小，使用 `vector` 而非 `map`；不要求顺序的情况下可以用 `unordered_` 系列，但在 Codeforces 上记得使用随机模数；
// 
// ## 初始代码
// CIALLO_CODE
#include <bits/stdc++.h>
#include <random>
using namespace std;

signed main() {

}
auto FAST_IO = cin.tie(nullptr)->sync_with_stdio(false);
// CIALLO_MD
// ## 类型定义
// CIALLO_CODE
using i8 = signed char;
using u8 = unsigned char;
using i32 = signed;
using u32 = unsigned;
using i64 = long long;
using u64 = unsigned long long;
using i128 = __int128;
using u128 = unsigned __int128;
// CIALLO_END

// CIALLO_MD
// ## 随机数生成
// CIALLO_CODE
mt19937 rng(std::chrono::steady_clock::now().time_since_epoch().count());
// CIALLO_END

// CIALLO_MD
// ## 随机哈希
// CIALLO_CODE
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
// CIALLO_END

inline void func() {
    // CIALLO_MD
    // ## 二分答案
    // CIALLO_CODE
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
    // CIALLO_END
    std::vector adj(114, std::vector<int>(514));
    // CIALLO_MD
    // ## Lambda 递归
    // CIALLO_CODE
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
    // CIALLO_END
}
