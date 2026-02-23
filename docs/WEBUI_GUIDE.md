# NovaScript WebUI 使用指南

## 快速开始

### 启动 WebUI 服务器

```bash
# 基本启动（默认端口 8080）
nova start

# 指定端口
nova start -p 3000

# 指定主机和端口
nova start -h 0.0.0.0 -p 8080

# 完整选项
nova start --host 127.0.0.1 --port 8080 --open
```

### 访问界面

启动后，在浏览器中打开：
```
http://127.0.0.1:8080
```

## 界面功能

### 1. Dashboard（仪表盘）

- **统计卡片**: 显示项目数、代码行数、包数量、运行时间
- **最近文件**: 快速访问最近编辑的文件
- **快捷操作**: 新建项目、打开文件、运行脚本、安装包
- **系统信息**: 显示操作系统、架构、主机名等

### 2. Code Editor（代码编辑器）

- **文件树**: 左侧显示项目文件结构
- **代码编辑**: 支持语法高亮、自动缩进
- **工具栏**: 保存、运行、格式化代码
- **状态栏**: 显示行数、列数、语言类型

快捷键：
- `Ctrl+S` - 保存文件
- `Ctrl+R` - 运行代码
- `Ctrl+F` - 格式化代码

### 3. Terminal（终端）

- **命令执行**: 直接运行 Bash/NovaScript 命令
- **命令历史**: 使用上下箭头查看历史命令
- **清屏按钮**: 一键清除终端输出

示例命令：
```bash
nova run script.nova
ls -la
pwd
```

### 4. File Manager（文件管理器）

- **目录浏览**: 点击文件夹进入子目录
- **文件操作**: 上传、下载、删除文件
- **路径导航**: 向上一级、刷新文件列表

### 5. Packages（包管理）

- **包列表**: 显示已安装的包
- **搜索功能**: 搜索可用的包
- **安装/卸载**: 一键管理包

可用包：
- `image-generator` - 图片生成器
- `code-editor` - 代码编辑器增强
- `terminal` - 终端模拟器
- `file-manager` - 文件管理器

### 6. Image Generator（图片生成器）

- **创建图片**: 设置宽度、高度、背景色
- **预览**: 实时预览生成的图片
- **格式**: 支持 .novaimg 格式

### 7. Projects（项目管理）

- **项目列表**: 显示所有项目
- **新建项目**: 选择模板创建新项目
- **打开项目**: 点击进入项目编辑器

项目模板：
- `Empty Project` - 空项目
- `Hello World` - 示例项目
- `CLI Application` - 命令行应用
- `Web Application` - Web 应用
- `Library` - 库项目

### 8. Settings（设置）

- **外观**: 主题（亮色/暗色）、字体大小
- **编辑器**: 自动保存、行号显示
- **服务器**: 端口配置

## 主题系统

### 切换主题

1. 点击右上角的太阳/月亮图标
2. 或在设置中选择主题：
   - System - 跟随系统
   - Light - 亮色主题
   - Dark - 暗色主题（默认）

### 主题颜色

暗色主题使用深蓝色调，亮色主题使用浅灰色调，都配有紫色渐变的强调色。

## API 接口

WebUI 提供 RESTful API 供外部调用：

### GET /api/status
获取服务器状态
```json
{"status":"running","version":"1.0.0"}
```

### GET /api/system/info
获取系统信息
```json
{
  "os":"Linux",
  "arch":"aarch64",
  "hostname":"termux",
  "user":"user"
}
```

### GET /api/packages/list
获取包列表
```json
{
  "packages":[
    {"name":"image-generator","description":"...","installed":true}
  ]
}
```

### GET /api/files/list?path=/path
获取文件列表
```json
{
  "files":[
    {"name":"file.nova","type":"file","size":1024}
  ]
}
```

### POST /api/terminal/exec
执行终端命令
```json
{"output":"command output"}
```

## 自定义

### 修改端口

编辑 `webui/server.sh`：
```bash
WEBUI_PORT="${WEBUI_PORT:-9000}"  # 改为 9000
```

### 添加自定义页面

1. 在 `webui/templates/` 创建 HTML 文件
2. 在 `index.html` 添加导航项
3. 在 `main.js` 添加交互逻辑

### 扩展功能包

在 `packages/` 目录创建新包：
```bash
packages/
└── my-package/
    ├── my-package.sh      # 主要功能
    ├── description.txt    # 描述
    └── static/            # 静态资源（可选）
```

## 故障排除

### 无法启动服务器

1. 检查端口是否被占用：
```bash
netstat -tlnp | grep 8080
```

2. 尝试其他端口：
```bash
nova start -p 3000
```

### Python 后端不可用

如果没有 Python，可以使用 netcat 后端：
```bash
# 安装 netcat
pkg install netcat-openbsd  # Termux
apt install netcat-openbsd  # Linux

# 启动
nova start
```

### 界面显示异常

1. 清除浏览器缓存
2. 检查浏览器兼容性（推荐 Chrome/Firefox）
3. 确保 JavaScript 已启用

## 性能优化

### 减少内存使用

在设置中关闭自动保存和实时预览。

### 提高响应速度

1. 减少同时打开的文件数量
2. 定期清理终端输出
3. 使用搜索而非浏览查找文件

## 安全建议

1. 不要将服务器暴露在公网（默认绑定 127.0.0.1）
2. 如需远程访问，使用 SSH 隧道：
```bash
ssh -L 8080:localhost:8080 user@remote
```
3. 定期更新 NovaScript

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+S` | 保存 |
| `Ctrl+R` | 运行 |
| `Ctrl+O` | 打开文件 |
| `Ctrl+N` | 新建文件 |
| `Ctrl+P` | 命令面板 |
| `Ctrl+`` ` | 切换终端 |
| `F1` | 帮助 |
| `Esc` | 关闭弹窗 |

## 更新日志

### v1.0.0
- 初始版本
- Dashboard、编辑器、终端、文件管理器
- 包管理系统
- 图片生成器
- 主题系统
- 项目模板

---

**NovaScript Studio** - 让编程更简单！
