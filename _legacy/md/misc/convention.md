# 约定

1. C++ 版本：
   1. 最低支持版本：`c++17`；
   1. 默认版本：`gnu++23`；
2. 格式：
   1. 缩进宽度为 4 个空格；
   2. 大括号换行；
   3. 一元运算符不空格，其他运算符空一格；
3. 命名：
   1. 遵循 `GoLang` 的命名规范；
4. 其他：
   1. 使用邻接表存图；
   2. 使用 `0-indexed` 的左闭右闭区间；
   3. 使用解绑同步流的 `std::cin` 和 `std::cout` 输入输出；
   4. 使用 `using namespace std;`，非必要不使用 `#define int long long`；
   5. 使用局部变量而非全局变量，局部 `lambda` 而非全局函数；
   6. 使用 `emplace` 而非 `push`，使用 `contains` 而非 `count`；
   7. 若键值较小，使用 `vector` 而非 `map`；不要求顺序的情况下可以用 `unordered_` 系列，但在 Codeforces 上记得使用随机模数；
