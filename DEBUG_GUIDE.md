# Zsh 网络状态提示插件调试指南

本指南提供了多种调试方法来帮助您诊断和修复插件问题。

## 🔧 调试工具

### 1. 快速调试脚本
```bash
# 运行快速测试
./test_plugin.sh

# 运行简化调试
./simple_debug.sh

# 使用交互式调试工具
./debug.sh
```

### 2. 手动调试命令

#### 检查基本状态
```bash
# 加载插件
source ./zsh-network-status-prompt.plugin.zsh

# 检查网络状态
_zsh_network_status_get_status

# 检查代理状态
_zsh_network_status_is_proxy_enabled && echo "代理启用" || echo "代理禁用"

# 构建完整提示符
_zsh_network_status_build_prompt
```

#### 检查缓存状态
```bash
# 查看缓存文件位置
echo "网络缓存: $_ZSH_NETWORK_STATUS_CACHE_FILE"
echo "代理缓存: $_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE"

# 查看缓存内容
cat "$_ZSH_NETWORK_STATUS_CACHE_FILE"
cat "$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE"

# 查看缓存时间（macOS）
stat -f %Sm "$_ZSH_NETWORK_STATUS_CACHE_FILE"
```

#### 测试网络连通性
```bash
# 直接测试网络连接
_zsh_network_status_check_connectivity && echo "网络连通" || echo "网络不通"

# 手动 curl 测试
curl -s --head --connect-timeout 2 "https://www.google.com"
```

#### 测试代理功能
```bash
# 启用代理
start_proxy
_zsh_network_status_is_proxy_enabled && echo "代理启用" || echo "代理禁用"

# 禁用代理
end_proxy
_zsh_network_status_is_proxy_enabled && echo "代理启用" || echo "代理禁用"

# 手动刷新状态
zsh_network_status_refresh
```

## 🐛 常见问题及解决方法

### 问题 1: 插件不显示在提示符中
**诊断步骤:**
```bash
# 1. 检查插件是否正确加载
echo "$ZSH_NETWORK_STATUS_PROMPT_SIDE"

# 2. 检查 RPROMPT/PROMPT
echo "RPROMPT: $RPROMPT"
echo "PROMPT: $PROMPT"

# 3. 手动触发提示符更新
_zsh_network_status_precmd
```

**可能解决方案:**
- 确保插件在 `.zshrc` 中正确配置
- 检查是否与其他插件冲突
- 重新加载 zsh: `exec zsh`

### 问题 2: 网络状态不准确
**诊断步骤:**
```bash
# 1. 清除缓存重新测试
rm -f "$_ZSH_NETWORK_STATUS_CACHE_FILE"
_zsh_network_status_get_status

# 2. 测试不同主机
ZSH_NETWORK_STATUS_PROMPT_HOST="www.cloudflare.com"
_zsh_network_status_check_connectivity

# 3. 增加超时时间
ZSH_NETWORK_STATUS_PROMPT_TIMEOUT=5
_zsh_network_status_check_connectivity
```

### 问题 3: 代理状态检测错误
**诊断步骤:**
```bash
# 1. 检查环境变量
env | grep -i proxy

# 2. 检查代理缓存
cat "$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE"

# 3. 手动测试代理检测
_zsh_network_status_get_proxy_status
```

### 问题 4: 缓存不工作
**诊断步骤:**
```bash
# 1. 检查缓存目录权限
ls -la "$_ZSH_NETWORK_STATUS_CACHE_DIR"

# 2. 检查缓存文件
ls -la "$_ZSH_NETWORK_STATUS_CACHE_FILE"

# 3. 测试缓存写入
echo "test" > "$_ZSH_NETWORK_STATUS_CACHE_FILE"
cat "$_ZSH_NETWORK_STATUS_CACHE_FILE"
```

## 🔍 深度调试

### 启用 zsh 调试模式
```bash
# 开启 zsh 调试
set -x

# 加载插件并测试
source ./zsh-network-status-prompt.plugin.zsh
_zsh_network_status_build_prompt

# 关闭调试
set +x
```

### 使用 zsh 调试器
```bash
# 安装 zsh-debugger (如果需要)
# 然后在函数中添加断点
_zsh_network_status_get_status() {
    # 添加调试输出
    echo "DEBUG: 开始检查网络状态" >&2
    
    # 你的代码...
    
    echo "DEBUG: 网络检查完成，状态: $cached_status" >&2
}
```

### 性能分析
```bash
# 测试函数执行时间
time_test() {
    local start_time=$(date +%s.%N)
    "$@"
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    echo "函数 $1 执行时间: ${duration}秒"
}

# 使用示例
time_test _zsh_network_status_get_status
time_test _zsh_network_status_build_prompt
```

## 📊 调试输出分析

### 正常输出示例
```
网络状态: online
代理检测: 禁用
完整提示符: %F{green} net:(online)%f
```

### 异常输出示例
```
网络状态: (空)          # 可能是网络检查失败
代理检测: 启用          # 但环境变量显示未设置代理
完整提示符: %F{red} net:(offline P)%f  # 颜色和状态不匹配
```

## 🛠️ 自定义调试函数

你可以在插件中添加这些调试函数：

```bash
# 添加到插件文件末尾
debug_network_status() {
    echo "=== 网络状态调试 ==="
    echo "时间: $(date)"
    echo "主机: $ZSH_NETWORK_STATUS_PROMPT_HOST"
    echo "超时: $ZSH_NETWORK_STATUS_PROMPT_TIMEOUT"
    echo "状态: $(_zsh_network_status_get_status)"
    echo "连通: $(_zsh_network_status_check_connectivity && echo '是' || echo '否')"
    echo "缓存: $(cat "$_ZSH_NETWORK_STATUS_CACHE_FILE" 2>/dev/null || echo '无')"
    echo "================="
}
```

## 📝 调试日志

创建调试日志文件：
```bash
# 启用日志记录
ZSH_NETWORK_STATUS_DEBUG_LOG="/tmp/zsh-network-status-debug.log"

# 在函数中添加日志
_zsh_network_status_get_status() {
    [[ -n "$ZSH_NETWORK_STATUS_DEBUG_LOG" ]] && echo "$(date): 检查网络状态" >> "$ZSH_NETWORK_STATUS_DEBUG_LOG"
    
    # 原有代码...
}

# 查看日志
tail -f "$ZSH_NETWORK_STATUS_DEBUG_LOG"
```

## 🎯 逐步调试流程

1. **确认插件加载**: 检查是否有语法错误
2. **验证依赖**: 确认 `curl` 命令可用
3. **测试网络**: 手动测试网络连接
4. **检查缓存**: 验证缓存机制工作
5. **测试代理**: 验证代理检测逻辑
6. **检查提示符**: 确认提示符正确显示
7. **性能测试**: 确保响应速度合理

使用这些调试方法，您应该能够快速定位和解决插件的任何问题！
