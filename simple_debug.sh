#!/bin/zsh

# 简化调试脚本
echo "🔧 Zsh 网络状态提示插件调试"
echo "=========================="

# 加载插件
source ./zsh-network-status-prompt.plugin.zsh

echo "📋 调试信息:"
echo "============"

echo "⚙️ 配置:"
echo "  检查主机: $ZSH_NETWORK_STATUS_PROMPT_HOST"
echo "  超时时间: $ZSH_NETWORK_STATUS_PROMPT_TIMEOUT 秒"
echo "  缓存过期: $ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION 秒"
echo "  显示位置: $ZSH_NETWORK_STATUS_PROMPT_SIDE"

echo ""
echo "🌐 环境变量:"
echo "  http_proxy: ${http_proxy:-未设置}"
echo "  https_proxy: ${https_proxy:-未设置}"
echo "  all_proxy: ${all_proxy:-未设置}"

echo ""
echo "💾 缓存状态:"
echo "  缓存目录: $_ZSH_NETWORK_STATUS_CACHE_DIR"
echo "  网络缓存文件: $_ZSH_NETWORK_STATUS_CACHE_FILE"
echo "  代理缓存文件: $_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE"

if [[ -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" ]]; then
    echo "  网络缓存: 存在 - 内容: $(cat "$_ZSH_NETWORK_STATUS_CACHE_FILE")"
else
    echo "  网络缓存: 不存在"
fi

if [[ -f "$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE" ]]; then
    echo "  代理缓存: 存在 - 内容: $(cat "$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE")"
else
    echo "  代理缓存: 不存在"
fi

echo ""
echo "🔍 功能测试:"
echo -n "  网络连通性: "
if _zsh_network_status_check_connectivity; then
    echo "✅ 连通"
else
    echo "❌ 不通"
fi

echo "  网络状态: $(_zsh_network_status_get_status)"
echo "  代理检测: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"
echo "  提示符: $(_zsh_network_status_build_prompt)"

echo ""
echo "🧪 代理测试:"
# 保存原始状态
orig_http_proxy="$http_proxy"

# 测试代理
export http_proxy="http://127.0.0.1:7890"
start_proxy
echo "  设置代理后: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"
echo "  代理提示符: $(_zsh_network_status_build_prompt)"

end_proxy
echo "  取消代理后: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"

# 恢复原始状态
export http_proxy="$orig_http_proxy"

echo ""
echo "✅ 调试完成"
