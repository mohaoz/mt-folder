# MTF 工作区状态汇报

更新日期：2026-08-07

## 结论

工具链已完成 Rust → Python 迁移并全部提交。当前成品为单文件 HTML、
四个打印版式的 PDF，以及一条可信的 Library Checker 验证链路：
**41 个模板、17 个有官方数据验证（16 项检查全部 AC）、其余 24 个
未覆盖模板全部通过语法编译门禁**。

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

## 最终产物与实测

| 产物 | 说明 | 实测 |
| --- | --- | --- |
| `preview/index.html` | 单文件离线模板站 | 41 卡片、17 徽章、零外部依赖、零重复 ID |
| `preview/mtf.pdf` | A4 竖排双栏彩色 | 全部字体嵌入、中文可搜索 |
| `preview/mtf-bw.pdf` | 竖排黑白（无高亮、灰阶章节条） | 同上 |
| `preview/mtf-landscape.pdf` | A4 横排三栏彩色 | 同上 |
| `preview/mtf-landscape-bw.pdf` | 横排三栏黑白 | 同上 |
| `yosupo/` | 生成的提交与 manifest | 16/16 AC，语法门禁 24/24 |

验证结果（本地全量）：

- 16 项官方检查全部 AC，含最慢用例耗时列与 TLE 复核留痕机制；
- 单元测试 58 个全部通过（含产物质量门禁）；
- 未覆盖模板语法编译 24/24 通过。

2026-08-04 从仓库目录使用项目内缓存重新全量验证：16/16 AC、
24/24 语法门禁通过；Dinic 最慢用例为 4.5s/5s，触发 60% 临界警告但
未失败。缓存、`preview/` 与 `yosupo/` 从此固定留在项目目录，不再散落到
上层工作区。

## 已知限制与约定

- Typst 0.15.1 的 HTML exporter 仍是实验特性，升级 Typst 需做 DOM
  回归（质量门禁可兜底大部分）；
- Poppler 对 Typst tagged PDF 仍有一条 `Suspects` 警告，不影响读取；
- 24 个模板尚无官方数据验证；其中 KMP、FFT、组合数等在 Library
  Checker 无对应题，需要本地对拍子系统（见 ROADMAP）；
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
