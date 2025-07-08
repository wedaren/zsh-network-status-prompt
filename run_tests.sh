#!/bin/zsh

# 测试脚本：run_tests.sh
# 用于测试 zsh-network-status-prompt 插件的所有功能

echo "🧪 开始 Zsh 网络状态提示插件测试..."
echo "=================================="

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_FILE="$SCRIPT_DIR/zsh-network-status-prompt.plugin.zsh"

# 检查插件文件是否存在
if [[ ! -f "$PLUGIN_FILE" ]]; then
    echo "❌ 错误：找不到插件文件 $PLUGIN_FILE"
    exit 1
fi

# 测试计数器
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "🔍 测试: $test_name ... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo "✅ 通过"
        ((TESTS_PASSED++))
    else
        echo "❌ 失败"
        ((TESTS_FAILED++))
    fi
}

# 清理环境
cleanup() {
    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
    unset ZSH_NETWORK_STATUS_PROMPT_HOST ZSH_NETWORK_STATUS_PROMPT_TIMEOUT
    unset ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION ZSH_NETWORK_STATUS_PROMPT_SIDE
    rm -f "${ZSH_CACHE_DIR:-$HOME/.zsh-cache}/zsh-network-status-prompt.cache"
}

# 加载插件
echo "📦 加载插件..."
source "$PLUGIN_FILE"

# 1. 基本功能测试
echo -e "\n🔧 基本功能测试"
echo "----------------"

run_test "curl 命令可用性检查" "command -v curl"
run_test "插件函数存在性检查" "type _zsh_network_status_is_proxy_enabled"
run_test "缓存目录创建" "test -d '$_ZSH_NETWORK_STATUS_CACHE_DIR'"

# 2. 代理检测测试
echo -e "\n🌐 代理检测测试"
echo "----------------"

cleanup
run_test "无代理环境检测" "! _zsh_network_status_is_proxy_enabled"

export http_proxy="http://127.0.0.1:8080"
run_test "http_proxy 检测" "_zsh_network_status_is_proxy_enabled"

cleanup
export HTTP_PROXY="http://127.0.0.1:8080"
run_test "HTTP_PROXY 检测" "_zsh_network_status_is_proxy_enabled"

cleanup
export https_proxy="https://127.0.0.1:8080"
run_test "https_proxy 检测" "_zsh_network_status_is_proxy_enabled"

cleanup
export all_proxy="socks5://127.0.0.1:1080"
run_test "all_proxy 检测" "_zsh_network_status_is_proxy_enabled"

# 3. 网络连接测试
echo -e "\n🔗 网络连接测试"
echo "----------------"

cleanup
run_test "Google 连接测试" "_zsh_network_status_check_connectivity"

ZSH_NETWORK_STATUS_PROMPT_HOST="invalid-host-that-does-not-exist.com"
run_test "无效主机连接测试" "! _zsh_network_status_check_connectivity"

# 4. 缓存机制测试
echo -e "\n💾 缓存机制测试"
echo "----------------"

cleanup
ZSH_NETWORK_STATUS_PROMPT_HOST="www.google.com"
rm -f "$_ZSH_NETWORK_STATUS_CACHE_FILE"

# 第一次调用应该创建缓存
_zsh_network_status_get_status >/dev/null
run_test "缓存文件创建" "test -f '$_ZSH_NETWORK_STATUS_CACHE_FILE'"

# 检查缓存内容
run_test "缓存内容有效" "test -s '$_ZSH_NETWORK_STATUS_CACHE_FILE'"

# 5. 提示符构建测试
echo -e "\n🎨 提示符构建测试"
echo "----------------"

cleanup
result=$(_zsh_network_status_build_prompt)
run_test "提示符包含 net:" "echo '$result' | grep -q 'net:'"

export http_proxy="http://127.0.0.1:8080"
result=$(_zsh_network_status_build_prompt)
run_test "代理指示器显示" "echo '$result' | grep -q 'P'"

# 6. 手动刷新功能测试
echo -e "\n🔄 手动刷新功能测试"
echo "--------------------"

cleanup
_zsh_network_status_get_status >/dev/null  # 创建缓存
run_test "刷新前缓存存在" "test -f '$_ZSH_NETWORK_STATUS_CACHE_FILE'"

zsh_network_status_refresh >/dev/null 2>&1
run_test "刷新后缓存清除" "! test -f '$_ZSH_NETWORK_STATUS_CACHE_FILE'"

# 7. 配置选项测试
echo -e "\n⚙️ 配置选项测试"
echo "----------------"

cleanup
ZSH_NETWORK_STATUS_PROMPT_HOST="www.cloudflare.com"
run_test "自定义主机配置" "_zsh_network_status_check_connectivity"

ZSH_NETWORK_STATUS_PROMPT_TIMEOUT=1
run_test "自定义超时配置" "test '$ZSH_NETWORK_STATUS_PROMPT_TIMEOUT' = '1'"

ZSH_NETWORK_STATUS_PROMPT_SIDE="PROMPT"
run_test "自定义提示符位置" "test '$ZSH_NETWORK_STATUS_PROMPT_SIDE' = 'PROMPT'"

# 8. 性能基准测试
echo -e "\n⚡ 性能测试"
echo "----------"

cleanup
_zsh_network_status_get_status >/dev/null  # 创建缓存

# 测试缓存命中性能
start_time=$(date +%s.%N)
for i in {1..5}; do
    _zsh_network_status_get_status >/dev/null
done
end_time=$(date +%s.%N)
cache_time=$(echo "$end_time - $start_time" | bc)

run_test "缓存性能测试 (<0.1秒)" "test $(echo '$cache_time < 0.1' | bc) = 1"

# 最终清理
cleanup

# 测试结果汇总
echo -e "\n📊 测试结果汇总"
echo "================"
echo "✅ 通过: $TESTS_PASSED"
echo "❌ 失败: $TESTS_FAILED"
echo "📈 总计: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n🎉 所有测试通过！插件功能正常。"
    exit 0
else
    echo -e "\n⚠️  有 $TESTS_FAILED 个测试失败，请检查插件实现。"
    exit 1
fi
