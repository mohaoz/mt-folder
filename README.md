# MTF

竞赛算法模板手册。一套 Typst 源码，三种产出：

- **PDF**（A4 打印速查）与 **HTML**（离线单文件，赛时搜索/复制）；
- **Library Checker 验证**：把手册里的 C++ 模板原样抽出来，对
  [judge.yosupo.jp](https://judge.yosupo.jp) 官方数据编译、运行、判题，
  确保"书里印的代码"就是"能 AC 的代码"。

## 仓库结构

```
mt-folder/
├── book.typ, template.typ      Typst 入口、样式与代码导出机制
├── src/                        手册正文（6 类 24 个章节文件，31 个代码模板）
├── mtf/                        Python 工具链：render / verify / TUI
│   └── verification/           验证子系统（导出、编译、判题、报告）
├── verify/catalog.json         模板 ↔ 官方题目的映射表
├── verify/library-checker/     每个验证项的 C++ driver
├── tests/                      单元测试（unittest）
└── yosupo/                     `mtf verify` 生成的提交与清单（git 忽略）
```

## 环境

- Python 3.11+
- [Typst](https://github.com/typst/typst) 0.15.1+
- Git
- 支持 GNU++17 的 `g++`

安装 Python 环境：

```console
uv sync
```

也可以使用普通虚拟环境：

```console
python -m pip install -e .
```

## 渲染

```console
uv run mtf render
```

默认在当前目录的 `preview/` 中生成 `index.html`（离线单文件，代码卡片带
复制按钮与 Library Checker 验证徽章）和四个打印版本的 PDF——供 ICPC
线下赛按赛场打印条件选用，PDF 中不含验证徽章：

| 文件 | 版式 | 配色 |
| --- | --- | --- |
| `mtf.pdf` | A4 竖排双栏 | 彩色 |
| `mtf-bw.pdf` | A4 竖排双栏 | 黑白（无语法高亮、灰阶章节条） |
| `mtf-landscape.pdf` | A4 横排三栏 | 彩色 |
| `mtf-landscape-bw.pdf` | A4 横排三栏 | 黑白 |

指定项目根目录或输出目录：

```console
uv run mtf render --root /path/to/mt-folder -o /path/to/preview
```

## Library Checker 验证

### 快速开始

三个路径默认值都跟随当前目录，所以**固定一个工作目录跑验证**，缓存和
产物才不会散落多处：

- `--root`：从 `$PWD` 向上查找 `book.typ`（在仓库外跑需显式指定）；
- `--library-checker-dir`：官方题库缓存，默认 `$PWD/.mtf/library-checker-problems`；
- `-o/--output-dir`：生成的提交与清单，默认 `$PWD/yosupo`。

在本机（缓存位于 `malgo/.mtf`）推荐从仓库外层统一运行：

```console
cd /home/mohao/malgo
uv run --project mt-folder mtf verify --root mt-folder
```

或在 `mt-folder` 内运行并复用已有缓存：

```console
uv run mtf verify --library-checker-dir ../.mtf/library-checker-problems
```

第一次运行会浅克隆官方
[`library-checker-problems`](https://github.com/yosupo06/library-checker-problems)，
再调用官方 `generate.py -p <problem>` 生成输入、答案和 checker。全部数据
首次生成约需 1–2 分钟和约 0.8 GiB；后续运行复用缓存，全量验证约 2 分钟。

### 每个验证项做什么

1. 用 `typst eval` 从 `.typ` 导出算法代码（与书中内容逐字节一致）；
2. 生成临时 `mtf_verify.hpp`，编译独立 C++ driver 做接口检查；
3. 内联头文件，产出可直接提交的单文件 `<check>.cpp`；
4. 以 GNU++17 `-O2` 编译；
5. 对每份官方输入运行，再交给官方 checker 判定。

### 计时与可靠性

- 导出、编译与数据生成并行执行（`-j/--jobs` 控制并发，数据生成最多
  并行两项）；**官方用例始终串行运行**，保证 wall-clock 计时可信。
- 每个验证项记录**最慢用例**的耗时；超过时限 60% 时在面板和 manifest
  中以 ⚠ 标记，提示该模板在评测机负载波动下有 TLE 风险。
- 首次 TLE 自动串行复核一次；复核通过会在结果中写明
  "`<用例>` 首次 TLE（x.xs），复核通过"，不静默掩盖。
- 每轮运行开始时清空输出目录的 `.verify/`：磁盘上出现的失败现场一定
  属于本轮运行。
- 退出码：全部通过为 0，任一失败为 1，可直接接脚本或 CI。

### 结果去哪看

- **终端 TUI**（交互终端自动启用）：实时表格逐项显示
  `AC n/n · 最慢 <用例> x.xs/时限`，⚠ 行黄色高亮；面板同时列出未验证
  模板。重定向输出或 CI 环境自动退化为无 ANSI 的文本日志。
- **`<output-dir>/README.md`**（manifest）：结果总表含"最慢用例"列、
  未验证模板清单与临界警告汇总。注意 manifest 记录的是**最后一次运行的
  范围**——`--check` 子集运行也会重写它。
- **失败现场**：`<output-dir>/.verify/logs/<check>/failure/` 保存复现
  输入、`actual.out`、`stderr.log` 与 `checker.log`；完整外部命令日志在
  `<output-dir>/.verify/logs/` 下按验证项分目录存放。

示例输出（plain 模式）：

```text
[unionfind] 官方测试 · passed · AC 18/18 · 最慢 max_random_01 0.0s/5s
[bipartitematching_dinic] 官方测试 · passed · AC 44/44 · ⚠ 最慢 augmented_cycle_02 4.2s/5s
summary: 7/7 passed, 0 failed, 24 unverified
```

### 常用选项

```console
# 只检查接口和 GNU++17 语法，不拉数据（约 10 秒）
uv run mtf verify --syntax-only

# 只验证指定 catalog 项（可重复；注意会重写 manifest）
uv run mtf verify --check unionfind --check staticrmq

# 并发数（作用于导出/编译/数据生成；判题始终串行）
uv run mtf verify -j 8

# 更新官方题库 / 清理并重新生成官方数据
uv run mtf verify --update
uv run mtf verify --rebuild-data

# 强制动态面板或稳定文本输出
uv run mtf verify --ui tui
uv run mtf verify --ui plain
```

### 新增验证项

验证映射集中在 [`verify/catalog.json`](verify/catalog.json)，算法正文不
含任何验证 metadata。当前 33 个模板中 13 个有正式验证，20 个在面板与
manifest 中明示"未独立验证"。给一个模板补上验证需要三步：

1. **确认 `inventory` 条目**：`{id, title, source, export}` 指向 `.typ`
   文件及其导出名（模板都已登记，通常无需改动）；
2. **写 driver** 到 `verify/library-checker/<check>.cpp`，遵守两条硬性
   合同（缺一不可，工具会拒绝运行）：
   - 恰好一行 `#include <mtf_verify.hpp>`；
   - 恰好一条注释
     `// competitive-verifier: PROBLEM https://judge.yosupo.jp/problem/<problem>`。
   导出代码会被包进 `namespace mtf { using namespace std; ... }`，driver
   通过 `mtf::` 使用模板（写法参考现有 driver）；
3. **在 `checks` 登记**：`{id, problem, driver, snippets, covers}`。
   `snippets` 列出注入的导出（`common` 中的 `types` 自动注入），`covers`
   声明该检查覆盖的 inventory id，且其导出必须出现在 `snippets` 中。

尚未验证的模板多数缺少可直接对应的官方题目：KMP 无前缀函数题
（zalgorithm 是不同算法）、浮点 FFT 做 convolution_mod 需拆系数（那测的
是 driver 而非模板）、组合数需要运行时模数而 ModInt 是编译期模数。为它
们补验证前先确认题目与模板契约真正一致。

## 开发检查

```console
python -m compileall -q mtf tests
python -m unittest discover -s tests -v
```

CI（`.github/workflows/check.yml`）运行单元测试、渲染冒烟与
`verify --syntax-only`；官方数据判题目前只在本地执行。项目不使用
shell 脚本。
