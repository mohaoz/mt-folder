#let html-css = ```css
:root {
  color-scheme: light;
  font-family: "Noto Serif CJK SC", serif;
  line-height: 1.65;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  color: #202124;
  background: #ffffff;
}

.mtf-nav {
  position: fixed;
  inset: 0 auto 0 0;
  width: 18rem;
  padding: 1.5rem;
  overflow-y: auto;
  border-right: 1px solid #e5e7eb;
  background: #fafafa;
  font-family: "Noto Sans CJK SC", sans-serif;
  font-size: 0.9rem;
}

.mtf-nav ol {
  padding-left: 1.25rem;
}

.mtf-main {
  max-width: 64rem;
  margin-left: 18rem;
  padding: 2rem 3rem 5rem;
}

h1, h2, h3, h4, h5, h6 {
  font-family: "Noto Sans CJK SC", sans-serif;
  line-height: 1.3;
}

pre {
  position: relative;
  overflow-x: auto;
  padding: 1rem;
  border: 1px solid #e5e7eb;
  border-radius: 0.4rem;
  background: #f8f8f8;
  line-height: 1.45;
  tab-size: 4;
}

pre code {
  font-family: "DejaVu Sans Mono", "Noto Sans Mono CJK SC", monospace;
  font-size: 0.85rem;
}

.copy-code {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  padding: 0.2rem 0.55rem;
  border: 1px solid #d1d5db;
  border-radius: 0.25rem;
  background: #ffffff;
  cursor: pointer;
}

@media (max-width: 960px) {
  .mtf-nav {
    position: static;
    width: auto;
    border-right: 0;
    border-bottom: 1px solid #e5e7eb;
  }

  .mtf-main {
    margin-left: 0;
    padding: 1.25rem;
  }
}
```.text

#let html-js = ```js
document.addEventListener("DOMContentLoaded", () => {
  for (const block of document.querySelectorAll("pre")) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "copy-code";
    button.textContent = "复制";
    button.addEventListener("click", async () => {
      const code = block.querySelector("code");
      await navigator.clipboard.writeText(code?.innerText ?? block.innerText);
      button.textContent = "已复制";
      window.setTimeout(() => button.textContent = "复制", 1200);
    });
    block.appendChild(button);
  }
});
```.text

#let snippet(
  code,
  header: none,
  starter: none,
  targets: ("web", "pdf", "verify"),
) = context {
  let marker = []
  if header != none and targets.contains("verify") {
    marker = metadata((
      kind: "mtf-snippet",
      header: header,
      code: code.text,
    ))
  }
  if starter != none {
    marker = marker + metadata((
      kind: "mtf-starter",
      language: starter,
      code: code.text,
    ))
  }

  let output = if target() == "html" { "web" } else { "pdf" }
  let displayed = if targets.contains(output) { code } else { [] }
  marker + displayed
}

#let web-only(body) = context {
  if target() == "html" { body }
}

#let pdf-only(body) = context {
  if target() == "paged" { body }
}

#let pdf-book(body) = {
  set page(
    paper: "a4",
    margin: (x: 1.25cm, y: 1.2cm),
    numbering: "1",
    footer: context align(center, counter(page).display()),
  )
  set text(
    font: ("Noto Serif CJK SC", "Libertinus Serif"),
    size: 9pt,
    lang: "zh",
  )
  set par(justify: true, leading: 0.65em)
  set heading(numbering: "1.1")
  show raw: set text(
    font: ("DejaVu Sans Mono", "Noto Sans Mono CJK SC"),
    size: 7pt,
  )
  set raw(tab-size: 4)

  align(center, text(20pt, weight: "bold")[莫号模板库])
  v(0.8em)
  outline(title: [目录], depth: 2)
  pagebreak()
  body
}

#let html-book(body) = html.elem("html", attrs: (lang: "zh-CN"))[
  #html.elem("head")[
    #html.elem("meta", attrs: (charset: "utf-8"))
    #html.elem("meta", attrs: (
      name: "viewport",
      content: "width=device-width, initial-scale=1",
    ))
    #html.elem("title")[莫号模板库]
    #html.elem("style")[#html-css]
  ]
  #html.elem("body")[
    #html.elem("nav", attrs: (class: "mtf-nav"))[
      *目录*
      #outline(title: none, depth: 2)
    ]
    #html.elem("main", attrs: (class: "mtf-main"))[
      #title[莫号模板库]
      #body
    ]
    #html.elem("script")[#html-js]
  ]
]

#let book(body) = context {
  set document(
    title: [莫号模板库],
    description: [算法竞赛模板及说明],
  )
  if target() == "html" {
    html-book(body)
  } else {
    pdf-book(body)
  }
}
