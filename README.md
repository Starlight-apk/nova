<div align="center">

# 🌌 NovaScript

> **v1.0.0** - 下一代高性能脚本编程语言

**基于 Bash · 完整工具链 · WebUI 支持 · Termux 优化**

[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg?style=for-the-badge)](https://github.com/novascript/nova/releases)
[![Bash](https://img.shields.io/badge/Bash-%3E%3D4.0-green.svg?style=for-the-badge&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Size](https://img.shields.io/badge/size-%3C1MB-lightgrey.svg?style=for-the-badge)](.)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows%20%7C%20Termux%20%7C%20ARM64-lightgrey.svg?style=for-the-badge)](.)
[![Stars](https://img.shields.io/github/stars/novascript/nova?style=for-the-badge&logo=github)](https://github.com/novascript/nova/stargazers)

---

### 🌍 选择语言 / Select Language

[🇨🇳 简体中文](README.md) · [🇺🇸 English](README.en.md)

---

> **📢 新功能** - WebUI 工作室现已可用！
>
> - 🎨 **精美界面** - 现代化 Dashboard + 侧边导航
> - 📝 **代码编辑** - 语法高亮 + 实时预览
> - 💻 **终端模拟** - 内置终端模拟器
> - 📦 **包管理** - nova pkg 企业级包管理器
> - 🔌 **功能扩展** - 图片生成器、文件管理器等
>
> 详见：[WebUI 使用指南](./docs/WEBUI_GUIDE.md)

---

<!-- Logo -->
<div align="center">
  <img src="https://raw.githubusercontent.com/novascript/nova/main/assets/logo.svg" alt="NovaScript Logo" width="180" />
</div>

[🚀 快速开始](#-快速开始) · [📦 核心模块](#-核心模块) · [🏗️ 架构设计](#️-架构设计) · [🌐 WebUI](#-webui) · [📖 文档](#-文档) · [💬 社区](#-社区)

</div>

---

## 📑 目录导航

<details open>
<summary><b>点击展开/收起完整目录</b></summary>

- [✨ 特性亮点](#-特性亮点)
- [📊 性能对比](#-性能对比)
- [🚀 快速开始](#-快速开始)
- [📦 核心模块](#-核心模块)
  - [包管理器 (nova pkg)](#-包管理器-nova-pkg)
  - [标准库](#-标准库)
  - [API 库](#-api-库)
- [🏗️ 架构设计](#️-架构设计)
- [🌐 WebUI](#-webui)
- [💡 使用示例](#-使用示例)
  - [运行脚本](#-运行脚本)
  - [安装包](#-安装包)
  - [搜索包](#-搜索包)
  - [列出已安装包](#-列出已安装包)
  - [查看包信息](#-查看包信息)
  - [发布包](#-发布包)
  - [其他命令](#-其他命令)
- [🔧 API 参考](#-api-参考)
- [📱 平台支持](#-平台支持)
- [🤝 参与贡献](#-参与贡献)
- [📄 许可证](#-许可证)

</details>

---

## ✨ 特性亮点

<div align="center">

| 🎯 **超小体积** | ⚡ **高性能** | 🔌 **完整工具链** |
|:---:|:---:|:---:|
| <1MB | 原生 Bash | 编译/调试/测试 |

| 🎨 **精美 UI** | 🌐 **跨平台** | 🔌 **模块化** |
|:---:|:---:|:---:|
| WebUI 工作室 | 全平台支持 | 插件系统 |

| 🌍 **国际化** | 📦 **包管理** | 🔐 **安全性** |
|:---:|:---:|:---:|
| 多语言支持 | nova pkg 企业级 | 加密模块 |

</div>

---

## 📊 性能对比

| 指标 | NovaScript | Python | 优势 |
|------|------------|--------|------|
| **安装大小** | <1 MB | ~117 MB | **100x 小** |
| **启动时间** | <0.5s | ~2s | **4x 快** |
| **内存占用** | <10 MB | ~50 MB | **5x 少** |
| **依赖** | 0 | 多 | **零依赖** |

---

## 🚀 快速开始

### 安装

#### Termux (Android)

```bash
# 克隆仓库
git clone https://github.com/novascript/nova.git
cd nova

# 运行安装脚本
bash install.sh

# 验证安装
nova --version
```

#### Linux/macOS

```bash
git clone https://github.com/novascript/nova.git
cd nova
bash install.sh
source ~/.bashrc  # 或重启终端
```

#### Windows (Git Bash/WSL)

```bash
git clone https://github.com/novascript/nova.git
cd nova
export PATH="$PWD/bin:$PATH"
```

### Hello World

创建 `hello.nova`:

```bash
#!/bin/bash
echo "Hello, NovaScript!"
```

运行:

```bash
nova run hello.nova
```

### WebUI

```bash
# 启动 WebUI 服务器
nova start

# 在浏览器中打开
# http://127.0.0.1:8080
```

---

## 📦 核心模块

### 包管理器 (nova pkg)

NovaScript 配备企业级包管理系统 `nova pkg`，提供完整的依赖管理功能：

| 命令 | 描述 | 示例 |
|------|------|------|
| `init` | 初始化项目 | `nova pkg init my-project` |
| `install` | 安装包 | `nova pkg install lodash` |
| `remove` | 卸载包 | `nova pkg remove express` |
| `update` | 更新包 | `nova pkg update axios` |
| `search` | 搜索包 | `nova pkg search web` |
| `list` | 列出已安装包 | `nova pkg list --json` |
| `publish` | 发布包 | `nova pkg publish --dry-run` |
| `info` | 查看包信息 | `nova pkg info react` |
| `cache` | 缓存管理 | `nova pkg cache clean` |

**主要特性：**
- ✅ 语义化版本控制（SemVer）
- ✅ 依赖树解析与扁平化
- ✅ 循环依赖检测
- ✅ 多注册表支持
- ✅ Lock 文件锁定依赖
- ✅ 全局/局部安装模式
- ✅ 开发依赖与生产依赖分离
- ✅ 彩色 UI 与多种输出格式

### 标准库

| 模块 | 描述 | API 数量 |
|------|------|----------|
| `std/io` | 输入输出 | 15+ |
| `std/string` | 字符串处理 | 15+ |
| `std/math` | 数学函数 | 20+ |
| `std/json` | JSON 解析 | 7+ |
| `std/os` | 操作系统 | 20+ |

### API 库

| 模块 | 描述 | API 数量 |
|------|------|----------|
| `api/core` | 核心函数 | 100+ |
| `api/string` | 字符串 | 100+ |
| `api/array` | 数组操作 | 80+ |
| `api/math` | 数学 | 100+ |
| `api/io` | 输入输出 | 80+ |
| `api/http` | HTTP 客户端 | 50+ |
| `api/json` | JSON 处理 | 40+ |
| `api/crypto` | 加密 | 60+ |
| `api/data` | 数据处理 | 100+ |

**总计：1000+ API 函数**

---

## 🏗️ 架构设计

```
NovaScript/
├── bin/                    # 主程序入口
│   └── nova                # CLI 命令
├── lib/
│   ├── std/                # 标准库
│   └── api/                # API 库
│       ├── core.sh         # 核心 API
│       ├── module.sh       # 模块系统
│       └── github.sh       # GitHub 集成
├── src/                    # 核心源码
│   ├── core/               # 解释器
│   ├── compiler/           # 编译器
│   ├── crypto/             # 加密
│   └── i18n/               # 国际化
├── tools/                  # 开发工具
│   ├── debugger.sh         # 调试器
│   ├── test-framework.sh   # 测试框架
│   ├── logo.sh             # Logo 显示
│   └── nova-pkg.sh         # 包管理器 (nova pkg)
├── webui/                  # WebUI
│   ├── server.sh           # Web 服务器
│   ├── static/             # 静态资源
│   └── templates/          # 模板
├── packages/               # 功能包
│   ├── image-generator/    # 图片生成器
│   ├── code-editor/        # 代码编辑器
│   ├── terminal/           # 终端模拟器
│   └── file-manager/       # 文件管理器
└── docs/                   # 文档
```

---

## 🌐 WebUI

NovaScript 配备精美的 WebUI 工作室，提供：

- 📊 **Dashboard** - 项目统计、系统信息
- 📝 **代码编辑器** - 语法高亮、代码补全
- 💻 **终端模拟器** - 内置终端
- 📂 **文件管理器** - 文件浏览、上传下载
- 📦 **包管理器** - nova pkg 完整支持（安装/搜索/发布）
- 🎨 **图片生成器** - 创建和编辑图片
- ⚙️ **设置面板** - 主题、配置

### 启动 WebUI

```bash
nova start
# 访问 http://127.0.0.1:8080
```

---

## 💡 使用示例

### 运行脚本

```bash
nova run script.nova
```

### 安装包

```bash
# 使用 nova pkg 包管理器
# 初始化项目
nova pkg init my-project

# 安装包
nova pkg install lodash
nova pkg install express@4.18.0

# 从 GitHub 安装
nova pkg install novascript/image-generator
nova pkg install owner/repo@v1.0.0

# 保存依赖到 manifest
nova pkg install axios --save
nova pkg install jest --save-dev

# 全局安装
nova pkg install typescript --global
```

### 搜索包

```bash
# 搜索包
nova pkg search web
nova pkg search json --limit 10
```

### 列出已安装包

```bash
# 列出项目依赖
nova pkg list

# 列出全局包
nova pkg list --global

# JSON 格式输出
nova pkg list --json
```

### 查看包信息

```bash
# 查看包详情
nova pkg info lodash

# 查看最新版本
nova pkg info lodash --latest
```

### 发布包

```bash
# 发布到注册表
nova pkg publish

# 测试发布（不真正上传）
nova pkg publish --dry-run

# 发布到自定义注册表
nova pkg publish --registry https://my-registry.com
```

### 其他命令

```bash
# 更新所有包
nova pkg update

# 更新特定包
nova pkg update lodash

# 清理缓存
nova pkg cache clean

# 查看缓存大小
nova pkg cache size
```

### 显示 Logo

```bash
nova logo
```

---

## 🔧 API 参考

### Core API

```bash
api_core_version      # 版本号
api_core_os           # 操作系统
api_core_timestamp    # 时间戳
```

### String API

```bash
api_str_upper "hello"     # HELLO
api_str_lower "HELLO"     # hello
api_str_reverse "abc"     # cba
```

### HTTP API

```bash
api_http_get "https://api.example.com/data"
api_http_post "https://api.example.com/api" '{"key":"value"}'
```

---

## 📱 平台支持

| 平台 | 状态 | 优化 |
|------|------|------|
| Termux (Android) | ✅ 完整支持 | ARM64 优化 |
| Linux | ✅ 完整支持 | x64/ARM64 |
| macOS | ✅ 完整支持 | x64/ARM64 |
| Windows (Git Bash/WSL) | ✅ 支持 | x64 |

---

## 🤝 参与贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

---

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

<div align="center">

### 🌟 感谢使用 NovaScript！

**NovaScript - The Future of Scripting**

[⬆ 返回顶部](#-novascript)

</div>
