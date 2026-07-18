# 莫号模板库

莫号模板库（Mohao's Template Folder，MTF）把算法说明和 C++ 实现写在同一份
Typst 源文件中，再生成三种消费形式：

```text
src/**/*.typ ──Typst──→ HTML / PDF
      │
      └── metadata ──mtf──→ include/mtf/*.hpp
                                  │
solution.cpp ─────────────────────┴──mtf bundle──→ submission.cpp
```

- HTML 用于在线浏览和复制；
- PDF 用于打印，可以按属性排除不适合打印的章节；
- 生成头文件用于比赛时正常 `#include`，提交前再按需展开成单文件。

`mtf` 是一个 Rust CLI。它不解析或改写 C++，也不是第二套模板语言；代码内容由
Typst `raw.text` 原样提供，`mtf` 只验证 metadata、组装头文件和展开 include。

## 安装

先安装 Typst，再从本仓库安装 `mtf`：

```bash
cargo install --locked typst-cli
cargo install --locked --path .
```

构建 `mtf` 时会查询当前 Typst 源，并把生成头文件的快照嵌入二进制。因此安装后的
`mtf init` 不依赖网络，也不要求比赛目录位于本仓库内。

## 在线比赛

### 初始化空目录

```bash
mkdir cf-round
cd cf-round

mtf init --compiler g++ --std gnu++23
mtf new A B C
```

得到：

```text
cf-round/
├── mtf.toml
├── mtf.lock
├── .clangd
├── compile_flags.txt
├── .gitignore
├── .mtf/
│   ├── starter.cpp
│   └── include/mtf/...
├── A.cpp
├── B.cpp
└── C.cpp
```

`.mtf/include` 是固定的模板快照。clangd、实际编译和最终 bundle 都读取这同一份
代码。`mtf.toml` 是编译参数的来源；`.clangd` 和 `compile_flags.txt` 由 `mtf`
生成。新 workspace 默认使用 `-pipe -Wall -Wextra`，不开启任何优化。

`mtf new` 使用快照中的 `.mtf/starter.cpp` 创建比赛源文件。这份初始代码来自
Typst 的 `mtf-starter` metadata，不在 Rust 中硬编码。

使用 GNU C++ 时，`mtf init` 会预热共享的 `bits/stdc++.h` 预编译头。缓存依次位于
`$MTF_CACHE_DIR`、`$XDG_CACHE_HOME/mtf` 或 `$HOME/.cache/mtf`，按编译器、C++ 标准和 flags
隔离，并校验系统头文件依赖是否变化。每个 profile 约占 167 MiB，具体大小取决于
工具链。非 GCC、使用自定义 include flags 时会安全回退到普通编译；也可设置
`MTF_PCH=0` 显式禁用。

若要用某个模板仓库工作区的最新内容初始化，而不是二进制内嵌快照：

```bash
mtf init --library /path/to/mt-folder
```

已有比赛目录可以刷新：

```bash
mtf update
mtf update --library /path/to/mt-folder
```

### 编译和运行

```bash
mtf compile A.cpp
mtf run A.cpp < A.in
```

默认二进制写入 `.mtf/bin/A`。实际编译器、标准和 flags 来自 `mtf.toml`。
`mtf run` 使用编译器 depfile 跟踪源文件和头文件依赖；所有输入未变时直接复用
已有二进制。`mtf compile` 则始终强制重新编译。

比赛代码正常 include 所需模块：

```cpp
#include <mtf/graph/dijkstra.hpp>

const auto distance = mtf::dijkstra(graph, n, source);
```

若启用 `#define int long long`，所有标准库和 MTF include 都必须写在该宏之前；
生成头始终按普通 `int` 独立编译，不依赖这个宏。

参照 [ACL](https://github.com/atcoder/ac-library)，include 根目录 `mtf/` 对应唯一的
C++ 命名空间 `mtf`；`graph/`、`ds/` 等子目录只负责组织头文件，不生成
子命名空间。也可以使用总入口：

```cpp
#include <mtf/all.hpp>
```

`all.hpp` 和 ACL 的 `atcoder/all` 一样，只聚合各个 include；使用它会让最终提交
包含全部模块。

### 管道优先的提交

`bundle` 默认把最终 C++ 写到 stdout：

```bash
mtf bundle A.cpp > A.submit.cpp
mtf bundle < A.cpp > A.submit.cpp
```

`check` 是透明过滤器：先编译完整输入，成功后再逐字节输出；失败时不输出任何
payload。推荐提交链路：

```bash
set -o pipefail
mtf bundle A.cpp | mtf check | wl-copy
```

同时留档：

```bash
set -o pipefail
mtf bundle A.cpp | mtf check | tee A.submit.cpp | wl-copy
```

所有 payload 只写 stdout，进度和诊断只写 stderr。bundle 会：

- 递归展开字面形式的 `<mtf/...>` 或 `"mtf/..."`；
- 每个内部头文件只展开一次；
- 删除生成标记、内部 `#pragma once` 和内部 include；
- 保留标准库 include、用户源码、算法源码字符及生成的 namespace 包裹；
- 拒绝缺失头文件、依赖环和条件式内部 include。

完整的空目录演示位于 [`examples/contest`](examples/contest/README.md)。

## 编写模板

每个模块是普通 Typst 文档，说明和代码直接混排：

````typst
= 懒标记线段树

使用非递归实现，单次操作复杂度为 `O(log n)`。

#let lzseg = ```cpp
template <class S, class F>
struct LazySegTree {
    // ...
};
```

#snippet(lzseg, header: "ds/lazysegtree.hpp")
````

`#snippet` 显示 raw code，同时用 metadata 暴露 `lzseg.text`。Typst 中的裸代码
保持原样；生成 header 时，`mtf` 只在它外层添加必要的预处理内容和统一的
`namespace mtf` 包裹。头文件子目录不改变 namespace。生成头文件不会从渲染后的
HTML/PDF 反向抓代码。

因此文档中的裸名称 `LazySegTree`，通过 header 使用时对应
`mtf::LazySegTree`；bundle 只去掉内部 include，不会去掉该命名空间。

输出属性写在 snippet 上：

```typst
#snippet(modint, header: "ds/modint.hpp", targets: ("web", "verify"))
```

该例会让 ModInt 进入网页和验证头文件，但不进入 PDF。纯展示代码可以不指定
header：

```typst
#snippet(binary-search, targets: ("web", "pdf"))
```

整本入口是 [`book.typ`](book.typ)，公共渲染和 metadata 规则位于
[`template.typ`](template.typ)。

## 维护模板仓库

从 Typst metadata 生成开发用头文件：

```bash
mtf sync
mtf sync --check
```

结果写到忽略版本管理的 `include/mtf/`。

生成文档：

```bash
mtf render
mtf render --target html
mtf render --target pdf
```

默认输出为 `book/index.html` 和 `book/mtf.pdf`。Typst 的 HTML exporter 目前仍是
实验功能；仓库在其语义 HTML 上提供自己的布局、目录和复制按钮。

本地开发也可以不安装二进制：

```bash
cargo run --locked -- sync
cargo run --locked -- render
```

## 验证

```bash
./check.sh
```

检查范围包括：

- Rust 格式、Clippy 和单元测试；
- Typst metadata 与生成头文件确定性；
- PDF、HTML 实际编译；
- 每个生成头文件独立通过 C++ 语法检查；
- 从临时空目录执行 `init → compile/run → bundle → check`；
- stdin/file 两种 bundle 输入得到相同代码；
- `check` 成功时逐字节透传，失败时不产生 payload；
- Cargo 发布包可以在脱离仓库工作树后构建。

这些检查验证模板基础设施，不用手写样例重复证明经典算法正确性。算法语义验证可以
在生成的验证头文件之上接入 competitive-verifier/library-checker。
