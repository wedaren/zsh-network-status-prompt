#!/bin/zsh

# 简单测试脚本：test_plugin.sh
# 用于快速验证插件基本功能

echo "🚀 快速测试 Zsh 网络状态提示插件"
echo "================================"

# 加载插件
source ./zsh-network-status-prompt.plugin.zsh

echo -e "\n1. 🔍 基本信息检查"
echo "当前网络状态: $(_zsh_network_status_get_status)"
echo "代理状态: $(_zsh_network_status_is_proxy_enabled && echo '已启用' || echo '未启用')"
echo "完整提示符: $(_zsh_network_status_build_prompt)"

echo -e "\n2. 🌐 代理测试"
echo "设置代理变量..."
export http_proxy="http://127.0.0.1:8080"
echo "代理状态: $(_zsh_network_status_is_proxy_enabled && echo '已启用' || echo '未启用')"
echo "带代理提示符: $(_zsh_network_status_build_prompt)"

echo -e "\n3. 💾 缓存测试"
echo "缓存文件: $_ZSH_NETWORK_STATUS_CACHE_FILE"
echo "缓存存在: $(test -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" && echo '是' || echo '否')"
if [[ -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" ]]; then
    echo "缓存内容: $(cat "$_ZSH_NETWORK_STATUS_CACHE_FILE")"
fi

echo -e "\n4. 🔄 刷新测试"
echo "执行手动刷新..."
zsh_network_status_refresh

echo -e "\n5. ⚙️ 配置测试"
echo "当前配置:"
echo "  检查主机: $ZSH_NETWORK_STATUS_PROMPT_HOST"
echo "  超时时间: $ZSH_NETWORK_STATUS_PROMPT_TIMEOUT 秒"
echo "  缓存过期: $ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION 秒"
echo "  显示位置: $ZSH_NETWORK_STATUS_PROMPT_SIDE"

echo -e "\n6. 🎨 提示符演示"
echo "右侧提示符效果 (RPROMPT):"
ZSH_NETWORK_STATUS_PROMPT_SIDE="RPROMPT"
_zsh_network_status_precmd
echo "RPROMPT='$RPROMPT'"

echo -e "\n左侧提示符效果 (PROMPT):"
ORIGINAL_PROMPT="$PROMPT"
ZSH_NETWORK_STATUS_PROMPT_SIDE="PROMPT"
_zsh_network_status_precmd
echo "PROMPT='$PROMPT'"

# 恢复原始设置
PROMPT="$ORIGINAL_PROMPT"
unset http_proxy

echo -e "\n✅ 快速测试完成！"
echo "如需详细测试，请运行: ./run_tests.sh"
