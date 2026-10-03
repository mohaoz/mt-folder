# MTF

项目由通用代码文档生成工具（类似 mdBook / Javadoc，面向不同代码内容
输出 PDF 与 HTML）和具体竞赛算法模板库两部分组成。开发阶段保持高度
耦合，暂不推进拆分或重新定义通用工具的设计。

当前模板库使用同一套 Typst 源码提供 **PDF**（A4 打印速查）与
**HTML**（离线单文件，赛时搜索/复制）。自动化测试、Library Checker
判题工具与测试 CI 已移除；保留的历史题目映射仅供查阅，不表示当前实现已通过验证。

内容规范见 [CONTENT_GUIDE](docs/CONTENT_GUIDE.md)，历史结论与待办见
[PROJECT_NOTES](docs/PROJECT_NOTES.md)，Agent 执行规则见 [AGENTS](AGENTS.md)。

## 仓库结构

```
mt-folder/
├── book.typ, template.typ      Typst 入口、样式与代码导出机制
├── assets/mt-folder-logo.svg    HTML 页头与 favicon 共用的 SVG 标志
├── src/                        具体算法模板库的手册正文
├── mtf/                        Python 渲染工具链
├── verify/catalog.json         模板目录、搜索别名与历史官方题目映射
├── docs/CONTENT_GUIDE.md       正文边界与章节规范
├── docs/PROJECT_NOTES.md       决策、历史验证结论、研究结论与待办
├── docs/research/              机器可读历史快照，不参与渲染
├── ci/cloudflare_build.py      Cloudflare Pages 构建入口
└── .github/workflows/release.yml  PDF 与离线 HTML 的滚动发布
```

## 内容边界

具体模板库不在正文中建设算法知识库或题解库。`src/` 收录稳定
可复用的 Template、少量高频 Snippet，以及说明接口的最小 Usage；完整实现
只保留一份，以 Typst 正文为唯一代码真源。

`book.typ` 唯一负责一级标题和全书顺序，正文文件从二级标题开始。尚未形成
模板的候选研究结论集中在 `docs/PROJECT_NOTES.md`，不参与渲染，也不代表
后续一定收录。完整规则见 [`docs/CONTENT_GUIDE.md`](docs/CONTENT_GUIDE.md)。

## 章节分组

一级分类由 [OI Wiki](https://oi.wiki/) 顶层导航与
[Library Checker](https://judge.yosupo.jp/)（yosupo）题目分类合并而来：

| 章 | 内容 | 参考依据 |
| --- | --- | --- |
| 杂项 | 约定、语言惯用法、Gray Code、Bitmask 与 SOS 变换 | OI Wiki 杂项（高维前缀和归杂项即从其例） |
| 数学 | 数论、ModInt、组合数、线性基、矩阵、线性递推 | OI Wiki 数学；覆盖 yosupo 的 Number Theory / Enumerative Combinatorics / Linear Algebra |
| 数据结构 | DSU、树状数组、线段树家族、Trie、堆 | 两站同名分类 |
| 图论 | 最小生成树、最短路 → DAG → 连通性 → 流与匹配 | 两站同名分类 |
| 树上问题 | LCA、树上差分、Kruskal 重构树、虚树、DSU on Tree | yosupo Tree；OI Wiki 并入图论，取独立分类便于赛时检索 |
| 字符串 | 双模字符串哈希、KMP、Z 函数（exKMP） | 两站同名分类 |
| 多项式与卷积 | FFT、NTT | yosupo Polynomial + Convolution 合并 |

分组原则：

1. 骨架取两站交集；两站分歧时按赛时检索效率取舍
   （树上问题独立、SOS DP 留杂项）；
2. 条目稀少的相邻类目先合并（数学暂不拆数论/组合/线代，
   多项式与卷积同章），条目变多后按 yosupo 细分；
3. 杂项只收约定、语言惯用法和暂不值得单开章节的高频 snippet；成型算法
   一律进主题章；
4. 章内排序：前置依赖在前（ModInt 在组合数之前）、
   主题相邻（网络流与匹配连排）；
5. 离线算法为预留章，后续收录莫队等稳定模板时新开 `80_offline`，
   正文文件从 81 开始编号；
6. 计算几何为预留章（两站均设 Geometry），收录时新开
   `90_geometry`；
7. 新模板入库先对照两站分类定章，再登记 catalog 的 `inventory`。

## 环境

- Python 3.11+
- [Typst](https://github.com/typst/typst) 0.15.1+
- [LXGW WenKai](https://github.com/lxgw/LxgwWenKai)（PDF 正文字体）

安装 Python 环境：

```console
uv sync
```

也可以使用普通虚拟环境：

```console
python -m pip install -e .
```

## 渲染

### 仅 HTML

在仓库根目录执行以下命令，仅生成 HTML，参数与现有渲染器的 HTML 编译
一致，不执行 PDF 编译：

```console
mkdir -p preview
typst compile book.typ preview/index.html --root . --features html --pretty
```

对已授权修改，当且仅当 HTML 渲染结果会变化时更新 HTML；仅改管理文档不
渲染。直接编译不具备 `mtf render` 的暂存后替换机制。

HTML 页头和浏览器标签图标从 `assets/mt-folder-logo.svg` 内嵌同一份标志，
更新该文件后重新编译即可；分发离线 HTML 时不需要另外复制图片资源。

### HTML 与四份 PDF

仅在明确要求渲染 PDF 时使用下面的完整渲染命令。当前 CLI 没有 HTML-only
选项，不要把它作为仅预览 HTML 的快捷方式。

```console
uv run mtf render
```

默认在当前目录的 `preview/` 中生成 `index.html`（离线单文件，代码卡片带
复制按钮与历史 Library Checker 来源标签）和四个打印版本的 PDF——供 ICPC
线下赛按赛场打印条件选用，PDF 中不含历史来源标签：

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

## 模板目录与历史来源

[`verify/catalog.json`](verify/catalog.json) 继续提供渲染所需的模板目录、
搜索别名与历史 Library Checker 题目映射。路径保留以兼容现有 Typst 模板，
其中不再包含可执行的测试 driver 配置。

- `inventory`：`{id, title, source, export, aliases?}`，描述模板及其代码真源；
- `checks`：`{id, problem, covers}`，保留过去登记的题目与模板关系，
  仅用于历史来源链接和数量展示。

HTML 将这些链接明确标为“历史来源”，不声明当前实现已通过验证。原有
`mtf verify` 命令、测试 driver、终端验证面板及定期判题已移除。
历史验证结果与局限见 [项目结论](docs/PROJECT_NOTES.md)，不能当作当前通过证明。

## 部署

站点部署在 Cloudflare Pages（`mt-folder.mohao.me`）。CF 面板只需
一次性设置两项，其余全部在仓库内：

- **构建命令**：`sh build.sh`
- **构建输出目录**：`site`

`build.sh` 是四行入口，逻辑在 `ci/cloudflare_build.py`：CF 构建
镜像没有 typst 和 CJK 字体，脚本把 typst 与全部所需字体下载到
`.cf-deps/`、用 `TYPST_FONT_PATHS` 提供字体并在渲染前校验字体
齐全，再产出 1 HTML + 4 PDF 到 `site/`。若构建镜像的 Python
低于 3.11，在面板加环境变量 `PYTHON_VERSION=3.11`。

GitHub Actions 只保留 `release`：推送 `main` 后渲染四个打印 PDF 与
离线 HTML，并挂到滚动 Release `latest`。原 `check`、每周 `verify` 及
release 产物测试门禁已删除；构建命令失败仍会中止发布。

## 开发检查

仓库不再维护或运行自动化测试套件。需要时可做 Python 语法检查：

```console
python -m compileall -q mtf ci
```

这只检查语法，不证明模板正确性。渲染规则仍按 [AGENTS](AGENTS.md) 执行：
HTML 产出变化时仅渲染 HTML；只有明确要求时才渲染 PDF。
