#!/bin/zsh

# Zsh 网络状态提示插件调试工具
# 使用方法: source debug.sh 或 ./debug.sh

echo "🔧 Zsh 网络状态提示插件调试工具"
echo "================================"

# 加载插件
source ./zsh-network-status-prompt.plugin.zsh

# 调试函数：显示详细状态信息
debug_status() {
    echo "🔍 详细状态信息:"
    echo "  时间戳: $(date)"
    echo "  网络状态: $(_zsh_network_status_get_status)"
    echo "  代理检测: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"
    echo "  代理实际状态: $(_zsh_network_status_get_proxy_status)"
    echo "  完整提示符: $(_zsh_network_status_build_prompt)"
    echo ""
}

# 调试函数：显示环境变量
debug_env() {
    echo "🌐 环境变量:"
    echo "  http_proxy: ${http_proxy:-未设置}"
    echo "  https_proxy: ${https_proxy:-未设置}"
    echo "  all_proxy: ${all_proxy:-未设置}"
    echo "  HTTP_PROXY: ${HTTP_PROXY:-未设置}"
    echo "  HTTPS_PROXY: ${HTTPS_PROXY:-未设置}"
    echo "  ALL_PROXY: ${ALL_PROXY:-未设置}"
    echo ""
}

# 调试函数：显示缓存信息
debug_cache() {
    echo "💾 缓存信息:"
    echo "  缓存目录: $_ZSH_NETWORK_STATUS_CACHE_DIR"
    echo "  网络缓存文件: $_ZSH_NETWORK_STATUS_CACHE_FILE"
    echo "  代理缓存文件: $_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE"
    
    if [[ -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" ]]; then
        echo "  网络缓存存在: 是"
        echo "  网络缓存内容: $(cat "$_ZSH_NETWORK_STATUS_CACHE_FILE")"
        if [[ "$(uname)" == "Darwin" ]]; then
            echo "  网络缓存时间: $(stat -f %Sm "$_ZSH_NETWORK_STATUS_CACHE_FILE")"
        else
            echo "  网络缓存时间: $(stat -c %y "$_ZSH_NETWORK_STATUS_CACHE_FILE")"
        fi
    else
        echo "  网络缓存存在: 否"
    fi
    
    if [[ -f "$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE" ]]; then
        echo "  代理缓存存在: 是"
        echo "  代理缓存内容: $(cat "$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE")"
    else
        echo "  代理缓存存在: 否"
    fi
    echo ""
}

# 调试函数：显示配置信息
debug_config() {
    echo "⚙️ 配置信息:"
    echo "  检查主机: $ZSH_NETWORK_STATUS_PROMPT_HOST"
    echo "  超时时间: $ZSH_NETWORK_STATUS_PROMPT_TIMEOUT 秒"
    echo "  缓存过期: $ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION 秒"
    echo "  显示位置: $ZSH_NETWORK_STATUS_PROMPT_SIDE"
    echo ""
}

# 调试函数：测试网络连接
debug_connectivity() {
    echo "🔗 网络连接测试:"
    echo -n "  直接测试连接: "
    if _zsh_network_status_check_connectivity; then
        echo "✅ 成功"
    else
        echo "❌ 失败"
    fi
    
    echo -n "  详细 curl 测试: "
    if curl -s --head --connect-timeout "$ZSH_NETWORK_STATUS_PROMPT_TIMEOUT" "https://${ZSH_NETWORK_STATUS_PROMPT_HOST}" >/dev/null 2>&1; then
        echo "✅ 成功"
    else
        echo "❌ 失败"
        echo "  错误信息: $(curl -s --head --connect-timeout "$ZSH_NETWORK_STATUS_PROMPT_TIMEOUT" "https://${ZSH_NETWORK_STATUS_PROMPT_HOST}" 2>&1)"
    fi
    echo ""
}

# 调试函数：测试代理功能
debug_proxy() {
    echo "🔧 代理功能测试:"
    
    # 保存当前状态
    local orig_http_proxy="$http_proxy"
    local orig_https_proxy="$https_proxy"
    local orig_all_proxy="$all_proxy"
    
    # 测试无代理
    unset http_proxy https_proxy all_proxy
    echo "  无代理状态: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"
    
    # 测试 http_proxy
    export http_proxy="http://127.0.0.1:7890"
    echo "  设置 http_proxy: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"
    
    # 测试 start_proxy 函数
    unset http_proxy
    start_proxy
    echo "  start_proxy 后: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"
    
    # 测试 end_proxy 函数
    end_proxy
    echo "  end_proxy 后: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"
    
    # 恢复原始状态
    export http_proxy="$orig_http_proxy"
    export https_proxy="$orig_https_proxy"
    export all_proxy="$orig_all_proxy"
    echo ""
}

# 调试函数：性能测试
debug_performance() {
    echo "⚡ 性能测试:"
    
    # 清除缓存以测试首次调用
    rm -f "$_ZSH_NETWORK_STATUS_CACHE_FILE"
    
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)
    _zsh_network_status_get_status >/dev/null
    local end_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    if command -v bc >/dev/null 2>&1; then
        local duration=$(echo "$end_time - $start_time" | bc)
        echo "  首次调用耗时: ${duration}秒"
    else
        echo "  首次调用完成 (需要 bc 命令计算耗时)"
    fi
    
    # 测试缓存命中
    start_time=$(date +%s.%N 2>/dev/null || date +%s)
    _zsh_network_status_get_status >/dev/null
    end_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    if command -v bc >/dev/null 2>&1; then
        duration=$(echo "$end_time - $start_time" | bc)
        echo "  缓存命中耗时: ${duration}秒"
    else
        echo "  缓存命中完成 (需要 bc 命令计算耗时)"
    fi
    echo ""
}

# 主调试函数
debug_all() {
    debug_config
    debug_env
    debug_cache
    debug_status
    debug_connectivity
    debug_proxy
    debug_performance
}

# 调试菜单
debug_menu() {
    echo "选择调试选项:"
    echo "1) 完整调试信息"
    echo "2) 基本状态"
    echo "3) 环境变量"
    echo "4) 缓存信息"
    echo "5) 配置信息"
    echo "6) 网络连接测试"
    echo "7) 代理功能测试"
    echo "8) 性能测试"
    echo "9) 清理缓存"
    echo "0) 退出"
    echo ""
    echo -n "请输入选择 (0-9): "
}

# 清理缓存函数
debug_cleanup() {
    echo "🧹 清理缓存..."
    rm -f "$_ZSH_NETWORK_STATUS_CACHE_FILE"
    rm -f "$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE"
    echo "缓存已清理"
    echo ""
}

# 如果直接运行脚本，显示菜单
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"debug.sh" ]]; then
    while true; do
        debug_menu
        read choice
        case $choice in
            1) debug_all ;;
            2) debug_status ;;
            3) debug_env ;;
            4) debug_cache ;;
            5) debug_config ;;
            6) debug_connectivity ;;
            7) debug_proxy ;;
            8) debug_performance ;;
            9) debug_cleanup ;;
            0) echo "退出调试"; break ;;
            *) echo "无效选择，请重新输入" ;;
        esac
        echo "按 Enter 键继续..."
        read
        clear
    done
fi
