# NovaScript 快速入门指南

## 1. 安装

### Termux (推荐)

```bash
cd /storage/emulated/0/Kaifa/NovaScript
bash install-termux.sh
```

### 手动安装

```bash
# 添加环境变量
export NOVA_HOME="/storage/emulated/0/Kaifa/NovaScript"
export PATH="$NOVA_HOME/bin:$PATH"

# 添加到 ~/.bashrc 永久生效
echo 'export NOVA_HOME="/storage/emulated/0/Kaifa/NovaScript"' >> ~/.bashrc
echo 'export PATH="$NOVA_HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 2. 验证安装

```bash
nova --version
```

预期输出：
```
NovaScript v1.0.0
Build: 2026.02.23
Platform: Linux/aarch64
Environment: Termux
Architecture: ARM64 (optimized)
```

## 3. 运行第一个程序

```bash
# 运行示例
nova run examples/hello.nova
```

## 4. 创建新项目

```bash
# 初始化项目
nova init my-first-project
cd my-first-project

# 运行项目
nova run src/main.nova
```

## 5. 常用命令

| 命令 | 说明 |
|------|------|
| `nova run <文件>` | 运行脚本 |
| `nova compile <文件>` | 编译为字节码 |
| `nova init <项目名>` | 创建新项目 |
| `nova install <包>` | 安装包 |
| `nova build` | 构建项目 |
| `nova test` | 运行测试 |
| `nova debug <文件>` | 调试模式 |
| `nova encrypt <文件>` | 加密文件 |
| `nova help` | 显示帮助 |

## 6. 语言特性

### 变量

```nova
local name = "Nova"
local version = 1.0
```

### 函数

```nova
func greet(name) {
    io.print("Hello, " + name)
}
```

### 导入模块

```nova
import std.io
import std.math
import std.string
```

## 7. 获取帮助

```bash
# 查看所有命令
nova help

# 查看版本
nova --version

# 使用中文
nova --lang zh-CN help
```

## 8. 遇到问题？

- 查看文档：`docs/` 目录
- 查看示例：`examples/` 目录
- 报告问题：https://github.com/novascript/nova/issues

---

**祝你使用愉快！** 🚀
