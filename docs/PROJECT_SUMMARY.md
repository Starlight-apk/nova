# NovaScript 项目总结

## 项目信息

- **项目名称**: NovaScript
- **包名**: nova
- **版本**: 1.0.0
- **文件格式**: .nova
- **创建日期**: 2026 年 2 月 23 日

## 项目结构

```
NovaScript/
├── bin/
│   └── nova                    # 主程序入口
├── lib/
│   └── std/
│       ├── io.nova             # IO 标准库
│       ├── string.nova         # 字符串标准库
│       ├── math.nova           # 数学标准库
│       ├── json.nova           # JSON 标准库
│       └── os.nova             # OS 标准库
├── src/
│   ├── core/
│   │   ├── init.sh             # 核心初始化
│   │   └── interpreter.sh      # 解释器核心
│   ├── utils/
│   │   └── args.sh             # 参数解析
│   ├── crypto/
│   │   └── encrypt.sh          # 加密模块
│   ├── i18n/
│   │   ├── i18n.sh             # 国际化系统
│   │   └── locales/
│   │       ├── en.json         # 英文翻译
│   │       └── zh-CN.json      # 中文翻译
│   └── compiler/
│       └── compiler.sh         # 编译器
├── tools/
│   ├── package-manager.sh      # 包管理器
│   ├── debugger.sh             # 调试器
│   └── test-framework.sh       # 测试框架
├── examples/
│   ├── hello.nova              # Hello World 示例
│   ├── calculator.nova         # 计算器示例
│   └── encryption.nova         # 加密示例
├── docs/
│   └── QUICKSTART.md           # 快速入门指南
├── build.sh                    # 构建脚本
├── install-termux.sh           # Termux 安装脚本
├── nova.json                   # 项目配置
├── README.md                   # 项目说明
└── LICENSE                     # 许可证
```

## 核心特性

### 1. 语言解释器
- 词法分析器
- 变量管理
- 函数定义和调用
- 控制流（if/while/for）
- 模块系统
- 异常处理

### 2. 标准库
- **std/io**: 输入输出操作
- **std/string**: 字符串处理
- **std/math**: 数学函数
- **std/json**: JSON 解析/生成
- **std/os**: 操作系统功能

### 3. 开发工具链
- **编译器**: 将.nova 编译为字节码 (.nbc)
- **调试器**: 支持断点、单步执行、变量检查
- **包管理器**: 安装、更新、搜索、移除包
- **测试框架**: 断言、测试用例、测试运行器
- **构建系统**: 跨平台构建支持

### 4. 加密模块
- 5 级加密强度可选
- XOR 加密
- 替换加密
- 转置加密
- Base64 编码
- 哈希函数 (MD5, SHA1, SHA256)

### 5. 国际化 (i18n)
- 默认语言：英文
- 支持中文（简体）
- 可扩展其他语言
- 翻译占位符替换

### 6. 参数系统
- 长选项 (--option)
- 短选项 (-o)
- 带值选项 (--option=value)
- 标志选项
- 位置参数
- 参数验证

### 7. 平台支持
- **Termux**: 完整支持，优化内存使用
- **ARM64**: 原生优化
- **Linux**: 完整支持
- **macOS**: 完整支持
- **Windows**: Git Bash/WSL 支持

## CLI 命令

| 命令 | 说明 |
|------|------|
| `nova run` | 运行脚本 |
| `nova compile` | 编译为字节码 |
| `nova init` | 初始化项目 |
| `nova install` | 安装包 |
| `nova remove` | 移除包 |
| `nova search` | 搜索包 |
| `nova build` | 构建项目 |
| `nova test` | 运行测试 |
| `nova debug` | 调试模式 |
| `nova encrypt` | 加密文件 |
| `nova decrypt` | 解密文件 |
| `nova config` | 配置 |
| `nova clean` | 清理 |
| `nova version` | 版本信息 |
| `nova help` | 帮助 |

## 语言语法示例

```nova
# 导入模块
import std.io
import std.math
import std.string

# 变量
local name = "Nova"
local version = 1.0

# 函数
func greet(name) {
    io.print("Hello, " + name)
}

# 条件
if age >= 18 {
    io.print("Adult")
} else {
    io.print("Minor")
}

# 循环
for i in 1..10 {
    io.print(i)
}

# 使用标准库
io.print(string.len("hello"))  # 5
io.print(math.add(10, 5))      # 15
```

## 加密格式

NovaScript 使用自定义加密格式：
```
NOVA_ENC_v1_L{level}_{checksum}_{encrypted_data}
```

- Level 1: Base64 + XOR
- Level 2: + Reverse
- Level 3: + Substitution
- Level 4: + Transposition
- Level 5: + Checksum

## 性能优化

### ARM64 优化
- 减少内存使用
- 启用 ARM 特定优化

### Termux 优化
- 最大内存：256M
- 轻量级加密
- 减少并行处理

### 桌面优化
- 最大内存：512M
- 完整功能集

## 快速开始

### 安装（Termux）
```bash
cd /storage/emulated/0/Kaifa/NovaScript
bash install-termux.sh
```

### 运行示例
```bash
nova run examples/hello.nova
```

### 创建项目
```bash
nova init my-project
cd my-project
nova run src/main.nova
```

## 技术亮点

1. **纯 Bash 实现**: 无需额外依赖，跨平台运行
2. **模块化设计**: 易于扩展和维护
3. **完整工具链**: 从开发到部署的全套工具
4. **安全性**: 多层加密保护代码
5. **国际化**: 多语言支持
6. **性能优化**: 针对移动设备优化

## 未来计划

- [ ] 更多标准库模块
- [ ] 包注册表
- [ ] IDE 插件
- [ ] 更多语言翻译
- [ ] 性能基准测试
- [ ] 在线文档

---

**NovaScript - The future of scripting is here!** 🚀
