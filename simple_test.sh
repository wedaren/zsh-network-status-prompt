#!/bin/zsh

# 简化测试脚本：simple_test.sh
# 专注于核心功能测试，避免网络依赖

echo "🧪 Zsh 网络状态插件 - 核心功能测试"
echo "=================================="

# 加载插件
source ./zsh-network-status-prompt.plugin.zsh

echo -e "\n✅ 测试结果:"

# 1. 检查基本函数是否存在
echo -n "📦 插件加载: "
if type _zsh_network_status_is_proxy_enabled >/dev/null 2>&1; then
    echo "✅ 成功"
else
    echo "❌ 失败"
fi

# 2. 代理检测测试
echo -n "🌐 代理检测 (无代理): "
unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
if ! _zsh_network_status_is_proxy_enabled; then
    echo "✅ 正确"
else
    echo "❌ 错误"
fi

echo -n "🌐 代理检测 (有代理): "
export http_proxy="http://127.0.0.1:8080"
if _zsh_network_status_is_proxy_enabled; then
    echo "✅ 正确"
else
    echo "❌ 错误"
fi

# 3. 缓存目录
echo -n "💾 缓存目录: "
if [[ -d "$_ZSH_NETWORK_STATUS_CACHE_DIR" ]]; then
    echo "✅ 存在"
else
    echo "❌ 不存在"
fi

# 4. 提示符构建
echo -n "🎨 提示符构建: "
result=$(_zsh_network_status_build_prompt)
if [[ -n "$result" && "$result" == *"net:"* ]]; then
    echo "✅ 正常"
    echo "   结果: $result"
else
    echo "❌ 异常"
fi

# 5. 手动刷新功能
echo -n "🔄 刷新功能: "
# 确保有缓存文件
_zsh_network_status_get_status >/dev/null
if [[ -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" ]]; then
    zsh_network_status_refresh >/dev/null 2>&1
    if [[ ! -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" ]]; then
        echo "✅ 正常"
    else
        echo "❌ 缓存未清除"
    fi
else
    echo "⚠️  无缓存文件"
fi

# 6. 配置变量
echo -n "⚙️ 配置变量: "
if [[ -n "$ZSH_NETWORK_STATUS_PROMPT_HOST" && 
      -n "$ZSH_NETWORK_STATUS_PROMPT_TIMEOUT" &&
      -n "$ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION" &&
      -n "$ZSH_NETWORK_STATUS_PROMPT_SIDE" ]]; then
    echo "✅ 完整"
    echo "   主机: $ZSH_NETWORK_STATUS_PROMPT_HOST"
    echo "   超时: $ZSH_NETWORK_STATUS_PROMPT_TIMEOUT 秒"
    echo "   缓存: $ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION 秒"
    echo "   位置: $ZSH_NETWORK_STATUS_PROMPT_SIDE"
else
    echo "❌ 缺失"
fi

# 7. 依赖检查
echo -n "🔧 依赖检查: "
if command -v curl >/dev/null 2>&1; then
    echo "✅ curl 可用"
else
    echo "❌ curl 不可用"
fi

# 清理
unset http_proxy

echo -e "\n🎯 功能演示:"
echo "无代理状态: $(_zsh_network_status_build_prompt)"

export https_proxy="https://proxy.example.com:8080"
echo "有代理状态: $(_zsh_network_status_build_prompt)"

unset https_proxy

echo -e "\n📋 提示符集成演示:"
echo "设置 RPROMPT..."
ZSH_NETWORK_STATUS_PROMPT_SIDE="RPROMPT"
_zsh_network_status_precmd
echo "RPROMPT 内容: '$RPROMPT'"

echo -e "\n✅ 核心功能测试完成！"
echo "💡 插件已就绪，可以正常使用。"
