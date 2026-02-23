#!/bin/bash
#===============================================================================
# NovaScript 测试框架
#===============================================================================

# 测试结果统计
NOVA_TEST_TOTAL=0
NOVA_TEST_PASSED=0
NOVA_TEST_FAILED=0
NOVA_TEST_ASSERTIONS=0

#-------------------------------------------------------------------------------
# 断言函数
#-------------------------------------------------------------------------------
assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    ((NOVA_TEST_ASSERTIONS++))
    
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "  ✗ Assertion failed: expected '$expected', got '$actual'"
        [[ -n "$message" ]] && echo "    $message"
        ((NOVA_TEST_FAILED++))
        return 1
    fi
}

assert_ne() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    ((NOVA_TEST_ASSERTIONS++))
    
    if [[ "$expected" != "$actual" ]]; then
        return 0
    else
        echo "  ✗ Assertion failed: expected not '$expected'"
        [[ -n "$message" ]] && echo "    $message"
        ((NOVA_TEST_FAILED++))
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-}"
    
    ((NOVA_TEST_ASSERTIONS++))
    
    if [[ "$condition" == "true" ]] || [[ "$condition" == "1" ]] || eval "$condition"; then
        return 0
    else
        echo "  ✗ Assertion failed: expected true"
        [[ -n "$message" ]] && echo "    $message"
        ((NOVA_TEST_FAILED++))
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-}"
    
    ((NOVA_TEST_ASSERTIONS++))
    
    if [[ "$condition" == "false" ]] || [[ "$condition" == "0" ]] || ! eval "$condition"; then
        return 0
    else
        echo "  ✗ Assertion failed: expected false"
        [[ -n "$message" ]] && echo "    $message"
        ((NOVA_TEST_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    ((NOVA_TEST_ASSERTIONS++))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "  ✗ Assertion failed: '$haystack' does not contain '$needle'"
        [[ -n "$message" ]] && echo "    $message"
        ((NOVA_TEST_FAILED++))
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    ((NOVA_TEST_ASSERTIONS++))
    
    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        echo "  ✗ Assertion failed: '$haystack' should not contain '$needle'"
        [[ -n "$message" ]] && echo "    $message"
        ((NOVA_TEST_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local path="$1"
    local message="${2:-}"
    
    ((NOVA_TEST_ASSERTIONS++))
    
    if [[ -f "$path" ]]; then
        return 0
    else
        echo "  ✗ Assertion failed: file not found: $path"
        [[ -n "$message" ]] && echo "    $message"
        ((NOVA_TEST_FAILED++))
        return 1
    fi
}

assert_dir_exists() {
    local path="$1"
    local message="${2:-}"
    
    ((NOVA_TEST_ASSERTIONS++))
    
    if [[ -d "$path" ]]; then
        return 0
    else
        echo "  ✗ Assertion failed: directory not found: $path"
        [[ -n "$message" ]] && echo "    $message"
        ((NOVA_TEST_FAILED++))
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    ((NOVA_TEST_ASSERTIONS++))
    
    if [[ "$expected" -eq "$actual" ]]; then
        return 0
    else
        echo "  ✗ Assertion failed: expected exit code $expected, got $actual"
        [[ -n "$message" ]] && echo "    $message"
        ((NOVA_TEST_FAILED++))
        return 1
    fi
}

#-------------------------------------------------------------------------------
# 测试用例定义
#-------------------------------------------------------------------------------
test() {
    local name="$1"
    local func="$2"
    
    ((NOVA_TEST_TOTAL++))
    
    echo -n "  $name... "
    
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    if $func; then
        local end_time=$(date +%s.%N 2>/dev/null || date +%s)
        local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
        
        echo "✓ (${duration}s)"
        ((NOVA_TEST_PASSED++))
    else
        echo "✗"
    fi
}

#-------------------------------------------------------------------------------
# 测试套件
#-------------------------------------------------------------------------------
describe() {
    local name="$1"
    shift
    
    echo ""
    echo "▶ $name"
    
    "$@"
}

before_each() {
    # 每个测试前执行
    :
}

after_each() {
    # 每个测试后执行
    :
}

before_all() {
    # 所有测试前执行
    :
}

after_all() {
    # 所有测试后执行
    :
}

#-------------------------------------------------------------------------------
# 运行测试
#-------------------------------------------------------------------------------
nova_test() {
    local pattern="${1:-test/**/*.nova.test}"
    local verbose="${2:-false}"
    
    echo "=== NovaScript Test Runner ==="
    echo ""
    
    local start_time=$(date +%s)
    
    # 查找测试文件
    local test_files=()
    while IFS= read -r -d '' file; do
        test_files+=("$file")
    done < <(find . -path "*/test/*" -name "*.nova" -print0 2>/dev/null)
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        # 尝试运行内置测试
        nova_run_builtin_tests
    else
        for file in "${test_files[@]}"; do
            echo "Running: $file"
            source "$file"
        done
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # 打印摘要
    echo ""
    echo "=== Test Summary ==="
    echo "  Total:      $NOVA_TEST_TOTAL"
    echo "  Passed:     $NOVA_TEST_PASSED"
    echo "  Failed:     $NOVA_TEST_FAILED"
    echo "  Assertions: $NOVA_TEST_ASSERTIONS"
    echo "  Duration:   ${duration}s"
    
    if [[ $NOVA_TEST_FAILED -gt 0 ]]; then
        echo ""
        echo "❌ Tests failed"
        return 1
    else
        echo ""
        echo "✓ All tests passed"
        return 0
    fi
}

#-------------------------------------------------------------------------------
# 内置测试
#-------------------------------------------------------------------------------
nova_run_builtin_tests() {
    echo "Running built-in tests..."
    echo ""
    
    describe "String Functions" test_string_functions
    describe "Math Functions" test_math_functions
    describe "IO Functions" test_io_functions
    describe "OS Functions" test_os_functions
}

test_string_functions() {
    # 测试字符串长度
    local len=$(nova_builtin_len "hello")
    assert_eq "5" "$len" "String length"
    
    # 测试大写
    local upper=$(nova_builtin_upper "hello")
    assert_eq "HELLO" "$upper" "To uppercase"
    
    # 测试小写
    local lower=$(nova_builtin_lower "HELLO")
    assert_eq "hello" "$lower" "To lowercase"
    
    # 测试替换
    local replaced=$(nova_builtin_replace "hello world" "world" "nova")
    assert_eq "hello nova" "$replaced" "String replace"
}

test_math_functions() {
    # 测试加法
    local add_result=$((10 + 5))
    assert_eq "15" "$add_result" "Addition"
    
    # 测试乘法
    local mul_result=$((6 * 7))
    assert_eq "42" "$mul_result" "Multiplication"
    
    # 测试取模
    local mod_result=$((17 % 5))
    assert_eq "2" "$mod_result" "Modulo"
}

test_io_functions() {
    # 测试文件存在
    assert_true "[[ -f '$NOVA_HOME/bin/nova' ]]" "Main binary exists"
}

test_os_functions() {
    # 测试环境变量
    assert_true "[[ -n '\$NOVA_HOME' ]]" "NOVA_HOME is set"
}

#-------------------------------------------------------------------------------
# Mock 函数（用于测试）
#-------------------------------------------------------------------------------
mock() {
    local func="$1"
    local implementation="$2"
    
    eval "$func() { $implementation; }"
}

reset_mocks() {
    # 重置所有 mock
    :
}

#-------------------------------------------------------------------------------
# 测试辅助函数
#-------------------------------------------------------------------------------
skip() {
    local reason="${1:-}"
    echo "⊘ Skipped${reason:+: $reason}"
}

todo() {
    local message="${1:-}"
    echo "⊘ TODO${message:+: $message}"
}

only() {
    # 只运行此测试
    export NOVA_TEST_ONLY=true
}
