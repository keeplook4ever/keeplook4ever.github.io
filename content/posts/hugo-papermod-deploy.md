+++
title = "🚀 使用 Hugo + PaperMod + GitHub Actions 自动部署博客 | Build a Hugo Blog with PaperMod & GitHub Actions"
date = 2025-11-12T10:00:00+08:00
tags = ["Hugo", "PaperMod", "GitHub Pages", "DevOps", "静态博客"]
categories = ["Tech Notes"]
summary = "完整指南：从 Hugo 初始化到 GitHub Actions 自动部署，打造一个优雅、干净、自动化的个人博客。"
showToc = true
TocOpen = false
draft = false
[cover]
  image = "/images/hugo-papermod-cover.jpg"
  alt = "Hugo + PaperMod + GitHub Actions"
  caption = "Hugo + PaperMod 自动部署实战指南"
+++

> 🌱 本文记录了从本地调试、主题导入到 GitHub Actions 自动部署的一次完整实践。  
> 它既是一份技术笔记，也是一段重新搭建自己思想栖居地的过程。

---

## 🌿 前言 | Preface

很多人搭建 Hugo 博客时卡在「发布」这一步 —— 本地能跑，GitHub Pages 却 404。  
我也经历了从 `localhost` 跳转错误、`about` 页面丢失，到主题布局加载失败的过程。  
这篇文章记录了我完整的 Hugo + PaperMod 自动部署过程，帮助后来者少踩坑。

---

## 🧩 一、项目结构 | Project Structure

最终的 Hugo 博客项目结构如下：

```shell
.
├── _vendor
│   ├── github.com
│   └── modules.txt
├── archetypes
│   └── default.md
├── assets
├── content
│   ├── _index.md
│   ├── about
│   └── posts
├── data
├── go.mod
├── go.sum
├── hugo.toml
├── i18n
├── layouts
├── public
│   ├── 2025
│   ├── 404.html
│   ├── about
│   ├── assets
│   ├── categories
│   ├── index.html
│   ├── index.json
│   ├── index.xml
│   ├── posts
│   ├── robots.txt
│   ├── sitemap.xml
│   └── tags
├── scripts
│   └── build.sh
├── static
│   └── images
└── themes
    └── PaperMod
```

----

## ⚙️ 二、配置 Hugo Modules + PaperMod

### 1️⃣ 初始化 Hugo Module

```bash
hugo mod init github.com/keeplook4ever/keeplook4ever.github.io
```

这一步生成 `go.mod` 和 `go.sum`，让 Hugo 能通过模块系统管理主题。

### 2️⃣ 修改 `hugo.toml`

PaperMod 推荐使用 **模块导入**，不要再使用传统的 `theme = "PaperMod"`。

```shell
baseURL = "https://keeplook4ever.github.io/"
title = "Lennon — Blog"
languageCode = "en-us"
enableRobotsTXT = true

[module]
  [[module.imports]]
    path = "github.com/adityatelange/hugo-PaperMod"

[outputs]
  home = ["HTML", "RSS", "JSON"]

[params]
  defaultTheme = "auto"
  ShowReadingTime = true
  ShowCodeCopyButtons = true
  ShowShareButtons = true

  [params.profileMode]
    enabled = true
    title = "👋 Hi, I'm Lennon"
    subtitle = "Security engineer | Curious soul exploring technology and humanity"
    buttons = [
      { name = "About / 关于我", url = "/about/" },
      { name = "Posts", url = "/posts/" }
    ]
```

3️⃣ 拉取并 vendor 主题

```
hugo mod get github.com/adityatelange/hugo-PaperMod
hugo mod vendor
```

这会把主题完整放入 `_vendor/` 文件夹中，确保 CI 构建时可用。

----

## 🏗️ 三、配置自动部署 | GitHub Actions Workflow

`.github/workflows/pages.yml`：

```shell
name: Deploy Hugo to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: false
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.147.4'
          extended: true

      - name: Prepare Hugo Modules
        run: |
          hugo mod clean
          hugo mod get github.com/adityatelange/hugo-PaperMod
          hugo mod vendor

      - name: Build site
        run: hugo --minify --cleanDestinationDir --baseURL "https://keeplook4ever.github.io/"

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4

```

📘 **关键点：**

- 使用 Hugo Modules → 不依赖 submodule
- vendor 主题 → 保证 layout 存在
- push 即自动发布，无需手动上传

----

## 🧱 四、本地内容结构 | Content Setup

**首页**
 `content/_index.md`

```shell
+++
title = "Home"
draft = false
+++
```

**About 页面**
 `content/about/index.md`

```shell
+++
title = "About / 关于我"
url = "/about/"
draft = false
+++

## 🌿 About Me / 关于我

I’m a security engineer with eight years of experience —  
a technologist by profession, but also a seeker of meaning beyond code.

科技、音乐、电影、历史与运动是我探索世界的方式。  
在这里，我记录安全与生活的思考，也记录那些让我心动的瞬间。

```

----

## 🧹 五、清理与优化 | Cleaning Up

Hugo 会在 `public/` 输出静态文件。
 CI 每次都会重新生成，因此建议忽略：

```shell
echo "public/" >> .gitignore
git rm -r --cached public
git add .gitignore
git commit -m "chore: ignore build output"
git push

```

----

## ✅ 六、验证结果 | Verify

执行完 push 后，Actions 日志应出现：

```shell
drwxr-xr-x 3 runner runner ... public/about
-rw-r--r-- 1 runner runner ... public/about/index.html
```

访问：
 👉 https://keeplook4ever.github.io/about/
 🎉 成功显示 PaperMod 风格页面！

----

## ✨ 七、总结 | Summary

| 步骤     | 内容               | 关键点       |
| -------- | ------------------ | ------------ |
| 初始化   | `hugo mod init`    | 生成 go.mod  |
| 引入主题 | `[module.imports]` | 替代 theme = |
| 构建主题 | `hugo mod vendor`  | 确保布局存在 |
| 自动部署 | GitHub Actions     | 构建 + 发布  |
| 清理输出 | `.gitignore`       | 仓库更干净   |

----

## 💭 后记 | Afterword

技术之外，这个博客更像我与世界对话的方式。
 它记录安全工程，也记录生活与思考的痕迹。

愿我们都能找到自己热爱的事业，
 并在探索未知的路上，保持好奇与温度。 🌱

