# 空目录比赛工作流

先安装仓库根目录的 `mtf`，然后从任意位置执行：

```bash
DEMO=$(mktemp -d)
mtf init "$DEMO" --compiler g++ --std gnu++23
cp examples/contest/A.cpp "$DEMO/A.cpp"
cd "$DEMO"

mtf compile A.cpp
mtf run A.cpp
```

生成并检查最终提交源码：

```bash
set -o pipefail
mtf bundle A.cpp | mtf check > A.submit.cpp
```

也可以直接进入剪贴板：

```bash
set -o pipefail
mtf bundle A.cpp | mtf check | wl-copy
```

`A.cpp` 只 include Dijkstra，并通过 `mtf::dijkstra` 调用它。参照 ACL，include
根目录 `mtf/` 对应统一的 `namespace mtf`；`graph/` 等子目录只组织头文件。
Typst 中的裸代码本身不变。

因此最终单文件只包含公共 prelude 和 Dijkstra，不包含 DSU 等未使用模块。
`all.hpp` 仅聚合 include；`bundle` 展开它们时会保留生成的 namespace 包裹。
