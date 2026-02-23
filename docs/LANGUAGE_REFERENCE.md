# NovaScript 语言参考

## 概述

NovaScript 是一种基于 Bash 的高性能脚本编程语言，具有现代化的语法和完整的工具链。

## 文件结构

### .nova 文件

```bash
#!/bin/bash
#===============================================================================
# 文件头注释
#===============================================================================

# 导入模块
source "$NOVA_HOME/lib/std/io.nova"
source "$NOVA_HOME/lib/std/math.nova"

# 主代码
echo "Hello from NovaScript!"
```

## 语法

### 注释

```bash
# 单行注释

#===============================================================================
# 多行注释
# 使用多个 # 符号
#===============================================================================
```

### 变量

```bash
# 局部变量
local name = "Nova"
local version = 1.0
local count = 42

# 字符串
local greeting = "Hello, World!"

# 布尔值
local is_ready = true
local is_done = false
```

### 运算符

```bash
# 算术运算符
a=$((10 + 5))      # 加法
a=$((10 - 5))      # 减法
a=$((10 * 5))      # 乘法
a=$((10 / 5))      # 除法
a=$((10 % 3))      # 取模
a=$((2 ** 3))      # 幂

# 比较运算符
[[ $a -eq $b ]]    # 等于
[[ $a -ne $b ]]    # 不等于
[[ $a -lt $b ]]    # 小于
[[ $a -le $b ]]    # 小于等于
[[ $a -gt $b ]]    # 大于
[[ $a -ge $b ]]    # 大于等于

# 逻辑运算符
[[ $a && $b ]]     # 与
[[ $a || $b ]]     # 或
[[ ! $a ]]         # 非
```

### 控制流

```bash
# If 语句
if [[ $age -ge 18 ]]; then
    echo "Adult"
else
    echo "Minor"
fi

# If-elif-else
if [[ $score -ge 90 ]]; then
    echo "A"
elif [[ $score -ge 80 ]]; then
    echo "B"
elif [[ $score -ge 70 ]]; then
    echo "C"
else
    echo "F"
fi

# For 循环
for ((i=0; i<10; i++)); do
    echo "$i"
done

# For each
for item in apple banana cherry; do
    echo "$item"
done

# While 循环
while [[ $count -gt 0 ]]; do
    echo "$count"
    ((count--))
done

# Case 语句
case "$fruit" in
    apple)
        echo "It's an apple"
        ;;
    banana)
        echo "It's a banana"
        ;;
    *)
        echo "Unknown fruit"
        ;;
esac
```

### 函数

```bash
# 定义函数
greet() {
    local name="${1:-World}"
    echo "Hello, $name!"
}

# 带返回值的函数
add() {
    local a="$1"
    local b="$2"
    echo $((a + b))
}

# 调用函数
greet "Alice"
result=$(add 10 5)
```

### 数组

```bash
# 声明数组
local -a fruits=("apple" "banana" "cherry")

# 访问元素
echo "${fruits[0]}"      # apple
echo "${fruits[1]}"      # banana

# 数组长度
echo "${#fruits[@]}"     # 3

# 遍历数组
for fruit in "${fruits[@]}"; do
    echo "$fruit"
done
```

### 关联数组

```bash
# 声明关联数组
local -A person=(
    [name]="Alice"
    [age]=30
    [city]="New York"
)

# 访问值
echo "${person[name]}"   # Alice
echo "${person[age]}"    # 30

# 遍历
for key in "${!person[@]}"; do
    echo "$key: ${person[$key]}"
done
```

## 标准库

### std/io

```bash
source "$NOVA_HOME/lib/std/io.nova"

# 输出
io_print "Hello"
io_println "World"

# 输入
name=$(io_input "Enter your name: ")

# 文件操作
io_read_file "file.txt"
io_write_file "file.txt" "content"
io_file_exists "file.txt"
io_remove "file.txt"
```

### std/string

```bash
source "$NOVA_HOME/lib/std/string.nova"

len=$(string_len "hello")           # 5
upper=$(string_upper "hello")       # HELLO
lower=$(string_lower "HELLO")       # hello
trimmed=$(string_trim "  hello  ")  # hello
replaced=$(string_replace "hello world" "world" "nova")  # hello nova
contains=$(string_contains "hello" "ell")  # true
```

### std/math

```bash
source "$NOVA_HOME/lib/std/math.nova"

sum=$(math_add 10 5)        # 15
diff=$(math_sub 10 5)       # 5
prod=$(math_mul 10 5)       # 50
quot=$(math_div 10 5)       # 2
mod=$(math_mod 17 5)        # 2
pow=$(math_pow 2 3)         # 8
sqrt=$(math_sqrt 16)        # 4
rand=$(math_rand 100)       # 随机数 0-99
```

### std/json

```bash
source "$NOVA_HOME/lib/std/json.nova"

# 创建 JSON 对象
person=$(json_object "name=Alice" "age=30" "city=NYC")
# {"name":"Alice","age":"30","city":"NYC"}

# 创建 JSON 数组
fruits=$(json_array "apple" "banana" "cherry")
# ["apple","banana","cherry"]

# 获取值
name=$(json_get "$person" "name")
```

### std/os

```bash
source "$NOVA_HOME/lib/std/os.nova"

# 系统信息
os_type=$(os_type)           # linux/macos/windows
os_arch=$(os_arch)           # arm64/x64
is_termux=$(os_is_termux)    # true/false
is_arm64=$(os_is_arm64)      # true/false

# 环境变量
home=$(os_getenv "HOME")
os_set_env "MY_VAR" "value"

# 执行命令
result=$(os_system "ls -la")
```

## 加密

```bash
source "$NOVA_HOME/src/crypto/encrypt.sh"

# 加密字符串
encrypted=$(nova_encrypt_string "secret message" 3)
decrypted=$(nova_decrypt_string "$encrypted")

# 加密文件
nova_encrypt "file.nova" "file.nova.enc" 3
nova_decrypt "file.nova.enc" "file.nova.dec"

# 哈希
md5=$(nova_hash "text" md5)
sha256=$(nova_hash "text" sha256)
```

## 最佳实践

### 1. 使用局部变量

```bash
# 好
local name = "Alice"

# 避免
name = "Alice"  # 全局变量
```

### 2. 引用变量

```bash
# 好
echo "$name"
echo "${array[0]}"

# 避免
echo $name
echo ${array[0]}
```

### 3. 错误处理

```bash
if [[ ! -f "$file" ]]; then
    echo "Error: File not found" >&2
    exit 1
fi
```

### 4. 使用函数

```bash
# 将代码组织成函数
main() {
    # 主逻辑
}

main "$@"
```

## CLI 使用

```bash
# 运行脚本
nova run script.nova

# 编译
nova compile script.nova

# 调试
nova debug script.nova

# 加密
nova encrypt secret.nova -l 5

# 创建项目
nova init my-project

# 构建
nova build

# 测试
nova test
```

---

**NovaScript** - 让脚本编写更简单！
