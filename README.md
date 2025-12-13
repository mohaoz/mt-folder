# 介绍

**莫号模板库**（*Mohao's Template Folder, MTF*）是一个由我个人创建个人使用~~不~~欢迎贡献的算法竞赛模板库。

主要的设计灵感来自于 [AtCoder Library](https://atcoder.github.io/ac-library/production/document_en/index.html) 以及 [WIDA 的 XCPC 模板库](https://github.com/hh2048/XCPC)。

目前正在施工中……

## 新特性

- 使用 awk 处理文本文件。

使用方式：

```sh
./build src > out.md
```

或者

```sh
./build a.cpp > out.md
```

关于新特性，以下是 ChatGPT 5.2 提供的介绍：

本模板库在生成流程上做了一次**刻意的“降复杂度”重构**。

核心变化并不在于功能增加，而在于**实现方式的收敛**：不再依赖复杂的文档系统或 AST 级解析，而是使用 **awk + UNIX 管线** 对源码进行**单遍、流式处理**。

具体来说：

* 模板的**唯一真源是 C++ 源码本身**
  文档内容直接写在 `.cpp / .hpp` 中，通过约定好的注释标记进行区分，不再维护独立的 Markdown 或中间格式文件。

* 使用一个极小的 DSL（`// CIALLO_MD` / `// CIALLO_CODE` / `// CIALLO_END`）
  只表达三种状态：忽略、Markdown、代码。
  无嵌套、无参数、无隐式规则，降低长期维护成本。

* 构建过程是**纯文本、流式的**
  所有文件先拼接，再由 awk 进行一次从头到尾的扫描，不缓存、不回溯、不解析语法树，对文件规模和代码风格高度鲁棒。

* 输出始终写到 **stdout**
  是否重定向为文件、是否继续 pipe 给 Typst / Pandoc / 其他工具，完全由 shell 决定，保持工具的可组合性。

这种设计的直接结果是：

* 模板代码可以 **直接提交到 OJ 验证正确性**
* 文档生成过程足够简单，几乎不可能“神秘坏掉”
* 模板既适合在线查看，也适合后续生成 PDF 等打印版本

总体而言，这更接近一种**极简的 Literate Programming 实践**：
不试图让工具变聪明，而是通过明确约定，让流程变得可靠。

## PDF 输出

显然这是简易的。

具体来说，你可以：

```typst
#import "@preview/numbly:0.1.0": numbly
#import "@preview/cmarker:0.1.8": render-with-metadata as cmarker-render
#import "@preview/mitex:0.2.6": *

#set text(font: "Noto Serif CJK SC")

#set page(numbering: "1")

#let (meta, body) = cmarker-render.with(metadata-block: "frontmatter-yaml", math: mitex, scope: (image: (source, alt: none, format: auto) => []))(read("output.md"))

    
#let dt = datetime.today().display("[year]年[month]月[day]日")

#set page(header: align(center, dt))

#body
```

当然你也可以使用 Pandoc 将 Markdown 转换为 TeX 或者是其他的什么东西。

## HTML 输出

访问 https://mt-folder.mohao.me
