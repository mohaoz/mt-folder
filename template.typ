// 莫号模板库 · 渲染模板
//
// 视觉方向：“判题台”。等宽字体做骨架，绿色只表示一件事——Accepted。
// 代码块渲染为编辑器缓冲区（语言标签 + 验证徽章 + 复制按钮）；
// 验证徽章的数据直接来自 verify/catalog.json，与 `mtf verify` 同源。

#let catalog = json("/verify/catalog.json")

// inventory id -> Library Checker problem（仅含被 checks.covers 覆盖的模板）
#let verified-problems = {
  let mapping = (:)
  for check in catalog.checks {
    for item-id in check.at("covers", default: ()) {
      mapping.insert(item-id, check.problem)
    }
  }
  mapping
}

#let template-count = catalog.inventory.len()
#let verified-count = verified-problems.len()
#let category-count = {
  catalog.inventory.map(item => item.source.split("/").at(1)).dedup().len()
}

#let mono-fonts = ("DejaVu Sans Mono", "Noto Sans Mono CJK SC")
#let ac-green = rgb("#0e7a44")

// PDF 打印模式，由 `typst compile --input` 传入：
//   pdf-layout = portrait（A4 竖排双栏）| landscape（A4 横排三栏）
//   pdf-theme  = color | bw（黑白打印：灰阶章节条、无语法高亮）
#let pdf-layout = sys.inputs.at("pdf-layout", default: "portrait")
#let pdf-theme = sys.inputs.at("pdf-theme", default: "color")

#let html-css = ```css
:root {
  --bg: #f6f7f9;
  --surface: #ffffff;
  --ink: #1b2431;
  --muted: #5f6d7b;
  --line: #dfe5eb;
  --ac: #148a4d;
  --ac-ink: #0c6b3a;
  --ac-soft: #e5f5ec;
  --code-bg: #f4f6f8;
  --code-head: #eceff2;
  --font-mono: ui-monospace, "SF Mono", "Cascadia Mono", Consolas,
    "DejaVu Sans Mono", "Noto Sans Mono CJK SC", monospace;
  --font-body: "Noto Sans CJK SC", "PingFang SC", "Microsoft YaHei",
    system-ui, sans-serif;
  color-scheme: light;
}

:root[data-theme="dark"] {
  --bg: #0d1117;
  --surface: #131a22;
  --ink: #d9e1e8;
  --muted: #8b98a5;
  --line: #242f3b;
  --ac: #3fb950;
  --ac-ink: #56d364;
  --ac-soft: #12261a;
  --code-bg: #10171f;
  --code-head: #182029;
  color-scheme: dark;
}

/* Typst 导出的高亮是固定浅色内联样式；暗色主题按色值逐一重映射 */
:root[data-theme="dark"] pre span[style="color: #d73948"] { color: #ff7b72 !important; }
:root[data-theme="dark"] pre span[style="color: #4b69c6"] { color: #79c0ff !important; }
:root[data-theme="dark"] pre span[style="color: #b60157"] { color: #d2a8ff !important; }
:root[data-theme="dark"] pre span[style="color: #74747c"] { color: #8b949e !important; }
:root[data-theme="dark"] pre span[style="color: #198810"] { color: #7ee787 !important; }

* { box-sizing: border-box; }

html { scroll-behavior: smooth; }

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  * { transition: none !important; }
}

body {
  margin: 0;
  color: var(--ink);
  background: var(--bg);
  font-family: var(--font-body);
  font-size: 15px;
  line-height: 1.75;
}

::selection { background: var(--ac-soft); }

a { color: var(--ac-ink); }

:focus-visible {
  outline: 2px solid var(--ac);
  outline-offset: 2px;
}

/* ---- 侧栏 ---- */

.sidebar {
  position: fixed;
  inset: 0 auto 0 0;
  width: 19rem;
  display: flex;
  flex-direction: column;
  border-right: 1px solid var(--line);
  background: var(--bg);
  font-family: var(--font-mono);
}

.brand {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.55rem;
  padding: 1.25rem 1rem 0.8rem;
}

.brand-title {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  margin: 0;
  font-size: 15px;
  font-weight: 700;
  line-height: 1.4;
}

.brand-mark {
  color: var(--ac);
  font-weight: 700;
  letter-spacing: 0.04em;
}

.side-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  padding: 0.65rem 1rem;
  border-top: 1px solid var(--line);
  font-size: 11.5px;
}

.side-meta {
  margin: 0;
  color: var(--ac-ink);
  white-space: nowrap;
}

.side-pdfs {
  display: flex;
  align-items: center;
  gap: 0.55rem;
  margin: 0;
  color: var(--muted);
}

.side-pdfs svg { display: block; opacity: 0.75; }

.side-pdfs a {
  color: var(--muted);
  text-decoration: none;
  border-bottom: 1px dotted var(--line);
}

.side-pdfs a:hover { color: var(--ac-ink); border-bottom-color: var(--ac); }

.nav-search {
  margin: 0 1rem 0.3rem;
  padding: 0.55rem 0.75rem;
  border: 1.5px solid var(--line);
  border-radius: 8px;
  color: var(--ink);
  background: var(--surface);
  font: inherit;
  font-size: 13px;
}

.nav-search::placeholder { color: var(--muted); }

.nav-search:focus {
  border-color: var(--ac);
  box-shadow: 0 0 0 3px var(--ac-soft);
  outline: none;
}

.search-count {
  margin: 0 1rem 0.55rem;
  min-height: 1.1em;
  color: var(--muted);
  font-size: 11px;
}

.search-count.has-hits { color: var(--ac-ink); }

.content h3:target::before {
  content: "▸ ";
  color: var(--ac);
}

.sidebar nav {
  flex: 1;
  overflow-y: auto;
  padding: 0 0.6rem 2rem;
  font-size: 12.5px;
  scrollbar-width: thin;
  scrollbar-color: var(--line) transparent;
}

/* WebKit：滚动条默认隐形，悬停侧栏时浮现细条 */
.sidebar nav::-webkit-scrollbar { width: 5px; }

.sidebar nav::-webkit-scrollbar-track { background: transparent; }

.sidebar nav::-webkit-scrollbar-thumb {
  background: transparent;
  border-radius: 999px;
}

.sidebar:hover nav::-webkit-scrollbar-thumb { background: var(--line); }

.sidebar nav ol {
  margin: 0;
  padding: 0;
  list-style: none;
}

.sidebar nav ol ol { margin: 0 0 0.35rem 0.9rem; }

.sidebar nav li.is-hidden { display: none; }

.sidebar nav a {
  display: block;
  padding: 0.24rem 0.5rem;
  border-left: 2px solid transparent;
  border-radius: 0 4px 4px 0;
  color: var(--muted);
  text-decoration: none;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.sidebar nav a .prefix {
  color: var(--ac);
  margin-right: 0.4em;
}

/* Typst outline 的顶层条目包在 <div> 里 */
.sidebar nav li > div a {
  color: var(--ink);
  font-weight: 700;
  margin-top: 0.55rem;
}

.sidebar nav a:hover { color: var(--ac-ink); }

.sidebar nav a.is-current {
  border-left-color: var(--ac);
  color: var(--ac-ink);
  background: var(--ac-soft);
}

/* ---- 正文 ---- */

.content {
  margin-left: 19rem;
  min-height: 100vh;
  padding: 1.2rem 3rem 5rem;
  background: var(--surface);
}

.content-inner {
  max-width: 50rem;
  margin: 0 auto;
}

.brand-actions {
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.github-link {
  display: flex;
  align-items: center;
  padding: 0.32rem 0.45rem;
  border: 1px solid var(--line);
  border-radius: 6px;
  color: var(--muted);
}

.github-link:hover { color: var(--ac-ink); border-color: var(--ac); }

.theme-toggle {
  display: flex;
  align-items: center;
  padding: 0.32rem 0.45rem;
  border: 1px solid var(--line);
  border-radius: 6px;
  color: var(--muted);
  background: transparent;
  cursor: pointer;
  font: inherit;
}

.theme-toggle:hover { color: var(--ac-ink); border-color: var(--ac); }

h1, h2, h3, h4 {
  line-height: 1.35;
  scroll-margin-top: 1.2rem;
  font-family: var(--font-mono);
}

.content h2 {
  margin: 3.2rem 0 1rem;
  padding: 0.35rem 0.7rem;
  border-left: 3px solid var(--ac);
  background: var(--ac-soft);
  border-radius: 0 6px 6px 0;
  color: var(--ink);
  font-size: 17px;
}

.content h3 {
  margin: 2.4rem 0 0.7rem;
  font-size: 15.5px;
}

.content p, .content li { max-width: 46rem; }

.content li { margin: 0.15rem 0; }

.content code:not(pre code) {
  padding: 0.08rem 0.32rem;
  border: 1px solid var(--line);
  border-radius: 4px;
  background: var(--code-bg);
  font-family: var(--font-mono);
  font-size: 0.86em;
}

/* ---- 代码卡片：编辑器缓冲区 ---- */

.code-card {
  margin: 1rem 0 1.7rem;
  border: 1px solid var(--line);
  border-radius: 8px;
  overflow: hidden;
  background: var(--code-bg);
}

.code-head {
  display: flex;
  align-items: center;
  gap: 0.7rem;
  padding: 0.3rem 0.5rem 0.3rem 0.85rem;
  border-bottom: 1px solid var(--line);
  background: var(--code-head);
  font-family: var(--font-mono);
  font-size: 11.5px;
}

.code-lang { color: var(--muted); letter-spacing: 0.05em; }

.code-verified {
  color: var(--ac-ink);
  text-decoration: none;
  border: 1px solid var(--ac);
  border-radius: 999px;
  padding: 0 0.55rem;
  line-height: 1.6;
  background: var(--ac-soft);
}

.code-verified:hover { text-decoration: underline; }

.copy-code {
  margin-left: auto;
  padding: 0.14rem 0.6rem;
  border: 1px solid transparent;
  border-radius: 5px;
  color: var(--muted);
  background: transparent;
  cursor: pointer;
  font: inherit;
}

.copy-code:hover, .copy-code:focus-visible {
  color: var(--ac-ink);
  border-color: var(--ac);
}

.copy-code.is-success { color: var(--ac-ink); }
.copy-code.is-error { color: #d1242f; }

.code-card pre {
  margin: 0;
  padding: 0.85rem 1rem;
  overflow-x: auto;
  line-height: 1.55;
  tab-size: 4;
}

.code-card pre code {
  font-family: var(--font-mono);
  font-size: 13px;
}

/* ---- 移动端 ---- */

.nav-toggle {
  display: none;
  position: fixed;
  right: 1rem;
  bottom: 1rem;
  z-index: 30;
  padding: 0.5rem 0.9rem;
  border: 1px solid var(--line);
  border-radius: 999px;
  color: var(--ink);
  background: var(--surface);
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.18);
  cursor: pointer;
  font-family: var(--font-mono);
  font-size: 13px;
}

@media (max-width: 900px) {
  .sidebar {
    z-index: 20;
    width: min(19rem, 85vw);
    transform: translateX(-102%);
    transition: transform 0.18s ease-out;
    box-shadow: none;
  }

  body.nav-open .sidebar {
    transform: none;
    box-shadow: 0 0 40px rgba(0, 0, 0, 0.3);
  }

  .nav-toggle { display: block; }

  .content { margin-left: 0; padding: 1rem 1.1rem 4rem; }
}

@media print {
  .sidebar, .nav-toggle, .theme-toggle, .copy-code { display: none; }
  .content { margin: 0; padding: 0; }
  .code-card { break-inside: avoid; }
}
```.text

#let theme-boot-js = ```js
(() => {
  let theme = "light";
  try {
    const saved = localStorage.getItem("mtf-theme");
    theme = saved === "dark" || saved === "light"
      ? saved
      : (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
  } catch (error) {
    /* file:// 或隐私模式下没有 localStorage，跟随浅色 */
  }
  document.documentElement.dataset.theme = theme;
})();
```.text

#let html-js = ```js
document.addEventListener("DOMContentLoaded", () => {
  const fallbackCopy = (text) => {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    const copied = document.execCommand("copy");
    textarea.remove();
    if (!copied) {
      throw new Error("copy command failed");
    }
  };

  const copyText = async (text) => {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
    } else {
      fallbackCopy(text);
    }
  };

  // 所有代码块统一为“编辑器缓冲区”卡片；snippet 生成的卡片已带头部，
  // 散落的裸 pre 在这里补一个头部。
  for (const pre of document.querySelectorAll("main pre")) {
    let head = pre.closest(".code-card")?.querySelector(".code-head");
    if (!head) {
      const card = document.createElement("figure");
      card.className = "code-card";
      pre.replaceWith(card);
      head = document.createElement("figcaption");
      head.className = "code-head";
      const lang = document.createElement("span");
      lang.className = "code-lang";
      lang.textContent = "code";
      head.append(lang);
      card.append(head, pre);
    }

    const code = pre.querySelector("code") ?? pre;
    const button = document.createElement("button");
    button.type = "button";
    button.className = "copy-code";
    button.textContent = "复制";
    button.setAttribute("aria-label", "复制代码");
    button.addEventListener("click", async () => {
      try {
        await copyText(code.textContent || "");
        button.textContent = "已复制";
        button.classList.add("is-success");
      } catch {
        button.textContent = "复制失败";
        button.classList.add("is-error");
      }
      window.setTimeout(() => {
        button.textContent = "复制";
        button.classList.remove("is-success", "is-error");
      }, 1400);
    });
    head.append(button);
  }

  // 深浅色切换
  const toggle = document.querySelector(".theme-toggle");
  toggle?.addEventListener("click", () => {
    const next = document.documentElement.dataset.theme === "dark"
      ? "light"
      : "dark";
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem("mtf-theme", next);
    } catch (error) {
      /* 无持久化环境，仅本次生效 */
    }
  });

  // 侧栏搜索：过滤目录项并统计命中，Enter 跳转第一个匹配
  const search = document.querySelector(".nav-search");
  const searchCount = document.querySelector(".search-count");
  const navItems = [...document.querySelectorAll(".sidebar nav li")];
  let hitLinks = [];
  const applyFilter = () => {
    const query = search.value.trim().toLowerCase();
    for (const item of navItems) {
      item.classList.remove("is-hidden");
    }
    hitLinks = [];
    if (!query) {
      if (searchCount) {
        searchCount.textContent = "";
        searchCount.classList.remove("has-hits");
      }
      return;
    }
    for (const item of navItems) {
      const text =
        item.querySelector(":scope > a, :scope > div > a")?.textContent ?? "";
      const selfHit = text.toLowerCase().includes(query);
      const childHit = [...item.querySelectorAll("ol a")].some((a) =>
        a.textContent.toLowerCase().includes(query)
      );
      if (!selfHit && !childHit) {
        item.classList.add("is-hidden");
      }
    }
    hitLinks = [
      ...document.querySelectorAll(
        ".sidebar nav li:not(.is-hidden) a[href^='#']"
      ),
    ].filter((a) => a.textContent.toLowerCase().includes(query));
    if (searchCount) {
      searchCount.textContent = hitLinks.length
        ? `${hitLinks.length} 个匹配 · Enter 跳转`
        : "无匹配";
      searchCount.classList.toggle("has-hits", hitLinks.length > 0);
    }
  };
  search?.addEventListener("input", applyFilter);
  search?.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      hitLinks[0]?.click();
    } else if (event.key === "Escape" && search.value) {
      event.stopPropagation();
      search.value = "";
      applyFilter();
    }
  });

  document.addEventListener("keydown", (event) => {
    if (
      event.key === "/" &&
      search &&
      !/^(input|textarea)$/i.test(document.activeElement?.tagName ?? "")
    ) {
      event.preventDefault();
      search.focus();
    }
    if (event.key === "Escape") {
      document.body.classList.remove("nav-open");
    }
  });

  // 当前章节高亮
  const navLinks = new Map(
    [...document.querySelectorAll(".sidebar nav a[href^='#']")].map((a) => [
      decodeURIComponent(a.getAttribute("href").slice(1)),
      a,
    ])
  );
  const headings = [...document.querySelectorAll("main h2[id], main h3[id]")]
    .filter((h) => navLinks.has(h.id));
  if (headings.length > 0) {
    let currentLink = null;
    // 目录跟随：把当前条目滚到侧栏中部（编辑器 zz 式定位），
    // 用户正把光标放在侧栏上时不抢滚动
    const nav = document.querySelector(".sidebar nav");
    const follow = (link) => {
      if (!nav || nav.matches(":hover")) {
        return;
      }
      const navBox = nav.getBoundingClientRect();
      const linkBox = link.getBoundingClientRect();
      const offset = linkBox.top - navBox.top + nav.scrollTop;
      nav.scrollTo({
        top: Math.max(
          0,
          offset - (nav.clientHeight - linkBox.height) / 2
        ),
      });
    };
    const highlight = (id) => {
      const link = navLinks.get(id);
      if (!link || link === currentLink) {
        return;
      }
      currentLink?.classList.remove("is-current");
      link.classList.add("is-current");
      follow(link);
      currentLink = link;
    };
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            highlight(entry.target.id);
          }
        }
      },
      { rootMargin: "0px 0px -70% 0px" }
    );
    for (const heading of headings) {
      observer.observe(heading);
    }
    highlight(headings[0].id);
  }

  // 移动端目录抽屉
  const navToggle = document.querySelector(".nav-toggle");
  navToggle?.addEventListener("click", () => {
    document.body.classList.toggle("nav-open");
  });
  document.querySelector(".sidebar nav")?.addEventListener("click", (event) => {
    if (event.target.closest("a")) {
      document.body.classList.remove("nav-open");
    }
  });
});
```.text

// ---- 内容级工具 ----

#let verified-problem(id) = if (
  id != none and id in verified-problems
) { verified-problems.at(id) } else { none }

#let snippet(code, id: none, targets: ("web", "pdf")) = context {
  let output = if target() == "html" { "web" } else { "pdf" }
  if not targets.contains(output) { return }
  let problem = verified-problem(id)
  if output == "web" {
    html.elem("figure", attrs: (class: "code-card"))[
      #html.elem("figcaption", attrs: (class: "code-head"))[
        #html.elem("span", attrs: (class: "code-lang"))[C++17]
        #if problem != none {
          html.elem(
            "a",
            attrs: (
              class: "code-verified",
              href: "https://judge.yosupo.jp/problem/" + problem,
              target: "_blank",
              rel: "noopener",
              title: "已通过 Library Checker 官方数据验证",
            ),
          )[✓ 已验证 · #problem]
        }
      ]
      #code
    ]
  } else {
    // PDF 面向线下赛打印：验证徽章只属于屏幕（HTML）版本。
    code
  }
}

#let web-only(body) = context {
  if target() == "html" { body }
}

#let pdf-only(body) = context {
  if target() == "paged" { body }
}

// ---- PDF：赛用速查，彩色/黑白 × 竖排/横排 ----

#let pdf-book(body) = {
  let bw = pdf-theme == "bw"
  let landscape = pdf-layout == "landscape"
  let accent = if bw { luma(0) } else { ac-green }
  let ink = if bw { luma(0) } else { rgb("#1b2431") }
  let muted = if bw { luma(90) } else { rgb("#5f6d7b") }
  let line-color = if bw { luma(140) } else { rgb("#d7dee5") }

  set page(
    paper: "a4",
    flipped: landscape,
    margin: (x: 1.1cm, top: 1.45cm, bottom: 1.1cm),
    columns: if landscape { 3 } else { 2 },
    header: context {
      if counter(page).get().first() > 1 {
        grid(
          columns: (1fr, auto),
          text(6.5pt, font: mono-fonts, fill: muted)[
            莫号模板库 · GNU++17
          ],
          text(
            6.5pt,
            font: mono-fonts,
            fill: muted,
            counter(page).display("1 / 1", both: true),
          ),
        )
      }
    },
  )
  set columns(gutter: 0.75cm)
  set text(font: "Noto Sans CJK SC", size: 8pt, lang: "zh", fill: ink)
  set par(justify: true, leading: 0.62em, spacing: 0.85em)
  set heading(numbering: "1.1")
  // 黑白打印时关闭语法高亮：彩色 token 在灰阶下深浅不一，可读性反而差
  set raw(tab-size: 4, theme: if bw { none } else { auto })
  set list(indent: 0.5em, body-indent: 0.4em)

  show raw.where(block: true): it => block(
    width: 100%,
    inset: (x: 4.5pt, y: 4pt),
    radius: 1.5pt,
    stroke: 0.4pt + line-color,
    breakable: true,
  )[
    #set text(font: mono-fonts, size: 6.5pt)
    #set par(justify: false, leading: 0.5em)
    #it
  ]
  show raw.where(block: false): set text(size: 7.5pt)

  show heading.where(level: 1): it => block(
    width: 100%,
    inset: (x: 6pt, y: 4.5pt),
    radius: 1.5pt,
    fill: if bw { luma(232) } else { accent },
    above: 1.35em,
    below: 0.9em,
  )[
    #set text(
      size: 10pt,
      weight: "bold",
      fill: if bw { luma(0) } else { white },
      font: mono-fonts,
    )
    #it
  ]
  show heading.where(level: 2): it => block(above: 1.15em, below: 0.6em)[
    #set text(size: 9pt, weight: "bold", fill: ink, font: mono-fonts)
    #it
    #v(2.5pt)
    #line(length: 100%, stroke: 0.35pt + line-color)
  ]

  // 跨栏刊头
  place(top, scope: "parent", float: true)[
    #grid(
      columns: (auto, 1fr),
      align: (left + bottom, right + bottom),
      [
        #text(16pt, weight: "bold", font: mono-fonts, fill: accent)[MTF]
        #h(0.5em)
        #text(16pt, weight: "bold", font: mono-fonts)[莫号模板库]
      ],
      text(7pt, font: mono-fonts, fill: muted)[
        算法竞赛速查 · GNU++17 · #template-count 模板
      ],
    )
    #v(3pt)
    #line(length: 100%, stroke: 0.6pt + accent)
    #v(1pt)
  ]

  {
    show outline.entry.where(level: 1): set text(
      size: 7.5pt,
      weight: "bold",
    )
    show outline.entry: set text(size: 7pt)
    outline(title: none, depth: 2)
  }
  v(0.6em)
  body
}

// ---- HTML：单文件离线模板站 ----

#let html-book(body) = html.elem("html", attrs: (lang: "zh-CN"))[
  #html.elem("head")[
    #html.elem("meta", attrs: (charset: "utf-8"))
    #html.elem("meta", attrs: (
      name: "viewport",
      content: "width=device-width, initial-scale=1",
    ))
    #html.elem("meta", attrs: (
      name: "description",
      content: "算法竞赛模板、复杂度说明与 C++ 实现，Library Checker 官方数据验证",
    ))
    #html.elem("title")[莫号模板库]
    #html.elem("script")[#theme-boot-js]
    #html.elem("style")[#html-css]
  ]
  #html.elem("body")[
    #html.elem("aside", attrs: (class: "sidebar"))[
      #html.elem("div", attrs: (class: "brand"))[
        #html.elem("h1", attrs: (class: "brand-title"))[
          #html.elem("span", attrs: (class: "brand-mark"))[MTF]
          莫号模板库
        ]
        #html.elem("span", attrs: (class: "brand-actions"))[
          #html.elem("a", attrs: (
            class: "github-link",
            href: "https://github.com/mohaoz/mt-folder",
            target: "_blank",
            rel: "noopener",
            title: "GitHub 仓库",
            "aria-label": "GitHub 仓库",
          ))[
            #html.elem("svg", attrs: (
              width: "14",
              height: "14",
              viewBox: "0 0 16 16",
              fill: "currentColor",
              "aria-hidden": "true",
            ))[
              #html.elem("path", attrs: (
                d: "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27s1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8z",
              ))
            ]
          ]
          #html.elem("button", attrs: (
            class: "theme-toggle",
            type: "button",
            "aria-label": "切换深浅色主题",
            title: "切换深浅色主题",
          ))[
            #html.elem("svg", attrs: (
              width: "14",
              height: "14",
              viewBox: "0 0 24 24",
              fill: "none",
              stroke: "currentColor",
              "stroke-width": "2",
              "aria-hidden": "true",
            ))[
              #html.elem("circle", attrs: (cx: "12", cy: "12", r: "9"))
              #html.elem("path", attrs: (
                d: "M12 3a9 9 0 0 0 0 18z",
                fill: "currentColor",
                stroke: "none",
              ))
            ]
          ]
        ]
      ]
      #html.elem("input", attrs: (
        class: "nav-search",
        type: "search",
        placeholder: "搜索模板 · Enter 跳转（/ 聚焦）",
        "aria-label": "搜索模板",
      ))
      #html.elem("div", attrs: (
        class: "search-count",
        "aria-live": "polite",
      ))[]
      #html.elem("nav", attrs: ("aria-label": "目录"))[
        #outline(title: none, depth: 2)
      ]
      #html.elem("footer", attrs: (class: "side-foot"))[
        #html.elem("p", attrs: (
          class: "side-pdfs",
          "aria-label": "打印版式",
        ))[
          #html.elem("svg", attrs: (
            width: "13",
            height: "13",
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            "stroke-width": "2",
            "stroke-linecap": "round",
            "stroke-linejoin": "round",
            "aria-hidden": "true",
            role: "img",
            title: "打印版式",
          ))[
            #html.elem("path", attrs: (d: "M6 9V2h12v7"))
            #html.elem("path", attrs: (
              d: "M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2",
            ))
            #html.elem("rect", attrs: (
              x: "6",
              y: "14",
              width: "12",
              height: "8",
            ))
          ]
          #html.elem("a", attrs: (
            href: "mtf.pdf",
            title: "A4 竖排双栏 · 彩色",
          ))[竖彩]
          #html.elem("a", attrs: (
            href: "mtf-bw.pdf",
            title: "A4 竖排双栏 · 黑白",
          ))[竖黑]
          #html.elem("a", attrs: (
            href: "mtf-landscape.pdf",
            title: "A4 横排三栏 · 彩色",
          ))[横彩]
          #html.elem("a", attrs: (
            href: "mtf-landscape-bw.pdf",
            title: "A4 横排三栏 · 黑白",
          ))[横黑]
        ]
        #html.elem("p", attrs: (
          class: "side-meta",
          title: "已通过 Library Checker 官方数据验证的模板数",
        ))[✓ #verified-count/#template-count]
      ]
    ]
    #html.elem("main", attrs: (class: "content"))[
      #html.elem("div", attrs: (class: "content-inner"))[
        #body
      ]
    ]
    #html.elem("button", attrs: (
      class: "nav-toggle",
      type: "button",
      "aria-label": "打开目录",
    ))[☰ 目录]
    #html.elem("script")[#html-js]
  ]
]

#let book(body) = context {
  set document(
    title: [莫号模板库],
    description: [算法竞赛模板及说明],
  )
  if target() == "html" {
    set heading(numbering: "1.1")
    html-book(body)
  } else {
    pdf-book(body)
  }
}
