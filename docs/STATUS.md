# MTF 工作区状态汇报

更新日期：2026-08-30

## 结论

工具链已完成 Rust → Python 迁移并全部提交。当前成品为单文件 HTML、
四个打印版式的 PDF，以及一条可信的 Library Checker 验证链路：
**47 个模板、19 个有官方数据验证（18 项检查）。**
2026-08-10 最近一次全量运行仍是 43 个模板的基线：16 项官方检查
通过、Dinic 1 项性能超时，当时 25 个未覆盖模板全部通过语法
编译门禁。2026-08-30 已重新运行当前 47 个模板的独立及合并语法门禁；
NTT 另通过 `convolution_mod` 官方数据 53/53，FFT 与 NTT 通过 2000 组
随机朴素卷积对拍。

## 本次调整（相对上一版报告）

1. 工具链：Rust CLI、`check.sh`、`sync`/`bundle`/workspace 子系统与
   `include/mtf` 头文件树已全部删除，替代品是 `mtf` Python 包
   （`render` 与 `verify` 两个子命令）；残留的 `~/.cargo/bin/mtf`
   旧二进制已卸载。
2. 验证器加固：编译并行、判题串行保证计时可信；记录每项最慢用例，
   超时限 60% 标 ⚠；首次 TLE 自动复核并留痕；每轮清空 `.verify/`；
   片段内 `#include` 提升到 namespace 外；未进检查的模板逐个做
   `-fsyntax-only` 语法编译，失败即整体失败。
3. 内容扩充：新增可并堆（pb_ds）、矩阵快速幂、高维前缀和、
   势能线段树、可持久化权值线段树、Kruskal 重构树、无向图欧拉回路、
   `bitset` 线性基八个模板与线段树章节的 Kadane 实例；Dinic 换扁平存边
   并按层截断 BFS，
   最慢官方用例从 4.2–4.5s 降至当时实测 2.3s（5s 时限）。
4. 渲染重设计："判题台"风格：HTML 深浅双主题、侧栏搜索、编辑器式
   代码卡片带 catalog 驱动的验证徽章；PDF 面向 ICPC 线下赛，
   彩色/黑白 × 竖排双栏/横排三栏四个变体，打印版不含线上验证信息。
5. 质量门禁进 CI：HTML 锚点/唯一 ID/离线性/徽章计数与 catalog 一致、
   内联脚本过 Node 检查；PDF 逐变体断言 A4 版式、字体嵌入、文本可
   抽取。CI 先渲染再跑全部测试，另有每周一次的官方数据全量验证
   workflow（缓存题库数据）。
6. 内容边界收口：本仓库只维护模板、少量高频 snippet 和最小用法；
   一级标题改由 `book.typ` 统一持有，并增加正文完整纳入且一级标题不重复的
   结构测试。Trick 候选调研归档到 `docs/research/`，不进入手册正文。
7. `nk` 非几何内容筛选：新增 Z 函数/exKMP 和 Gray Code；Z 函数通过
   `zalgorithm` 官方 29 组数据，Gray Code 通过独立编译及穷举冒烟。
8. 2026-08-30 内容更新：新增双模字符串哈希、不依赖 `ModInt` 的
   All in One 组合数，以及大 `n`、小 `k` 时的非预处理组合数；目录展示到
   三级，组合数的三份实现收入同一二级主题；FFT 改为 `struct` 封装，并在
   同一“多项式卷积”主题下新增 NTT；NTT 已接入官方验证。

## 最终产物与实测

| 产物 | 说明 | 实测 |
| --- | --- | --- |
| `preview/index.html` | 单文件离线模板站 | 当前 catalog 为 47 卡片、19 徽章；本轮未运行产物质量门禁 |
| `preview/mtf.pdf` | A4 竖排双栏彩色 | 本轮未生成 |
| `preview/mtf-bw.pdf` | 竖排黑白（无高亮、灰阶章节条） | 本轮未生成 |
| `preview/mtf-landscape.pdf` | A4 横排三栏彩色 | 本轮未生成 |
| `preview/mtf-landscape-bw.pdf` | 横排三栏黑白 | 本轮未生成 |
| `yosupo/` | 生成的提交与 manifest | 本轮 NTT 官方数据 53/53；当前 47 个模板语法门禁全部通过 |

验证结果：

- 2026-08-30 使用 GCC 15 重新运行语法门禁：18 项 driver 接口编译通过，
  47 个 inventory 模板独立编译全部通过，全书合并编译通过；
- NTT 通过 Library Checker `convolution_mod` 官方数据 53/53；FFT 与 NTT
  实际实例化后通过 2000 组含空数组、负系数的随机朴素卷积对拍；
- 2026-08-10 最近一次原 17 项官方检查全量运行仍为 16 项通过、Dinic
  1 项性能超时；当时新增 `zalgorithm` 为 AC 29/29；
- Dinic 在前一次全量运行中首次 TLE 后串行复核通过；最终一次全量运行的
  `augmented_cycle_00` 初测与串行复核均超过 5s，故当前全量状态记为失败，
  失败现场保存在 `yosupo/.verify/logs/bipartitematching_dinic/failure/`；
- 2026-08-30 本轮只重新渲染 HTML，未生成打印 PDF；已运行相关单元测试、
  全量语法门禁、NTT 官方验证与 FFT/NTT 随机对拍，未运行产物质量门禁。

2026-08-04 从仓库目录使用项目内缓存重新全量验证：16/16 AC、
24/24 语法门禁通过；Dinic 最慢用例为 4.5s/5s，触发 60% 临界警告但
未失败。缓存、`preview/` 与 `yosupo/` 从此固定留在项目目录，不再散落到
上层工作区。

## 已知限制与约定

- Typst 0.15.1 的 HTML exporter 仍是实验特性，升级 Typst 需做 DOM
  回归（质量门禁可兜底大部分）；
- Poppler 对 Typst tagged PDF 仍有一条 `Suspects` 警告，不影响读取；
- Dinic 在 Library Checker 二分图最大匹配的极限用例上仍有 TLE 风险，
  在优化并稳定复现通过前不能宣称官方检查全绿；
- 28 个模板尚无官方数据验证；KMP、浮点 FFT 与组合数等需要本地对拍或
  适配验证契约。浮点 FFT 当前有随机对拍结果，但没有官方验证徽章；
- `mt-test/` 已改为自包含源码（不再依赖已删除的头文件树）。

## 本地预览

在 `mt-folder/` 执行：

```bash
python3 -m http.server 8000 --directory preview
```

验证：

```bash
uv run mtf verify
```
