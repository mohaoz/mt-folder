#import "../../template.typ": snippet, web-only

== 约定

+ C++ 版本：`gnu++20`
+ 格式：
   + 缩进宽度为 4 个空格；
   + 大括号换行；
   + 一元运算符不空格，其他运算符空一格；
+ 命名：
   + 遵循 `GoLang` 的命名规范；
+ 其他：
   + 使用 `0-indexed` 的左闭右开区间；
   + 使用解绑同步流的 `std::cin` 和 `std::cout` 输入输出；
   + 使用 `using namespace std;`；
   + 使用局部变量而非全局变量，局部 `lambda` 而非全局函数；
   + 使用 `emplace` 而非 `push`，集合查重使用 `contains`；
   + 若键值较小，使用 `vector` 而非 `map`；不要求顺序的情况下可以用 `unordered_` 系列，但在 Codeforces 上记得使用随机模数；

== 初始代码

#let initial = ```cpp
#include <bits/stdc++.h>
using namespace std;

int T{0};
void solve() {}

int main() {
    cin.tie(nullptr)->sync_with_stdio(false);
    if (!T)
        cin >> T;
    while (T--)
        solve();
}
```

#snippet(initial)

== 类型定义

#let types = ```cpp
using i8 = signed char;
using u8 = unsigned char;
using i32 = signed;
using u32 = unsigned;
using i64 = int64_t;
using u64 = uint64_t;
using i128 = __int128;
using u128 = unsigned __int128;
```

#snippet(types)

== 随机数生成

#let random-hash = ```cpp
using u64 = uint64_t;

// std::mt19937
mt19937 rng(std::chrono::steady_clock::now()
                .time_since_epoch()
                .count());
// splitmix64
struct custom_hash {
    static auto splitmix64(u64 x) {
        x += 0x9e3779b97f4a7c15;
        x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9;
        x = (x ^ (x >> 27)) * 0x94d049bb133111eb;
        return x ^ (x >> 31);
    }

    auto operator()(u64 x) const {
        static const u64 SEED =
            std::chrono::high_resolution_clock::
                now()
                    .time_since_epoch()
                    .count();
        return splitmix64(x + SEED);
    }
};
```

#snippet(random-hash)

== Gray Code

二进制反射 Gray Code，相邻整数的编码恰好相差一个二进制位。

- `GrayCode(x)` 把非负整数转成 Gray Code，复杂度 `O(1)`；
- `InverseGrayCode(g)` 还原原整数，复杂度 `O(log g)`。

#let gray-code = ```cpp
inline uint64_t GrayCode(uint64_t x) {
    return x ^ (x >> 1);
}

inline uint64_t InverseGrayCode(uint64_t g) {
    uint64_t x = 0;
    for (; g; g >>= 1)
        x ^= g;
    return x;
}
```

#snippet(gray-code, id: "gray-code")

== 二分答案

#let binary-search = ```cpp
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
```

#snippet(binary-search)

== Lambda 递归

#let lambda-recursion = ```cpp
std::vector<std::vector<int>> adj;
auto dfs1 = [&](auto&& self, int x,
                int p) -> void {
    for (auto y : adj[x]) {
        if (y == p)
            continue;
        self(self, y, x);
    }
};
dfs1(dfs1, 0, 0);
// std::function 版本
std::function<void(int, int)> dfs2 =
    [&](int x, int p) {
        for (auto y : adj[x]) {
            if (y == p)
                continue;
            dfs2(y, x);
        }
    };
```

#snippet(lambda-recursion)
