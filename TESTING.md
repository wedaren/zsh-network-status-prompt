# Zsh 网络状态提示插件测试指南

## 1. 功能测试

### 1.1 插件安装测试

首先，确保插件可以正常加载：

```bash
# 直接加载插件进行测试
source ./zsh-network-status-prompt.plugin.zsh

# 检查是否有错误输出
echo $?
```

### 1.2 依赖检查测试

测试 curl 命令依赖检查：

```bash
# 临时重命名 curl 来测试依赖检查
sudo mv /usr/bin/curl /usr/bin/curl.bak 2>/dev/null || echo "curl not in /usr/bin"
sudo mv /opt/homebrew/bin/curl /opt/homebrew/bin/curl.bak 2>/dev/null || echo "curl not in /opt/homebrew/bin"

# 重新加载插件，应该看到错误信息
source ./zsh-network-status-prompt.plugin.zsh

# 恢复 curl
sudo mv /usr/bin/curl.bak /usr/bin/curl 2>/dev/null || echo "curl.bak not found in /usr/bin"
sudo mv /opt/homebrew/bin/curl.bak /opt/homebrew/bin/curl 2>/dev/null || echo "curl.bak not found in /opt/homebrew/bin"
```

### 1.3 代理检测测试

```bash
# 测试无代理状态
unset http_proxy https_proxy all_proxy grpc_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY GRPC_PROXY
source ./zsh-network-status-prompt.plugin.zsh
echo "代理状态检测结果: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"

# 测试小写代理变量
export http_proxy="http://127.0.0.1:8080"
echo "设置 http_proxy 后: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"

# 测试大写代理变量
unset http_proxy
export HTTP_PROXY="http://127.0.0.1:8080"
echo "设置 HTTP_PROXY 后: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"

# 测试 https_proxy
unset HTTP_PROXY
export https_proxy="https://127.0.0.1:8080"
echo "设置 https_proxy 后: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"

# 测试 all_proxy
unset https_proxy
export all_proxy="socks5://127.0.0.1:1080"
echo "设置 all_proxy 后: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"

# 测试 grpc_proxy
unset all_proxy
export grpc_proxy="http://127.0.0.1:50051"
echo "设置 grpc_proxy 后: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"

# 测试 GRPC_PROXY
unset grpc_proxy
export GRPC_PROXY="http://127.0.0.1:50051"
echo "设置 GRPC_PROXY 后: $(_zsh_network_status_is_proxy_enabled && echo '启用' || echo '禁用')"

# 清理测试环境
unset http_proxy https_proxy all_proxy grpc_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY GRPC_PROXY
```

### 1.4 网络连接测试

```bash
# 测试正常网络连接
echo "网络连接测试 (google.com): $(_zsh_network_status_check_connectivity && echo '成功' || echo '失败')"

# 测试无效主机
ZSH_NETWORK_STATUS_PROMPT_HOST="invalid-host-that-does-not-exist.com"
echo "无效主机测试: $(_zsh_network_status_check_connectivity && echo '成功' || echo '失败')"

# 恢复默认主机
ZSH_NETWORK_STATUS_PROMPT_HOST="www.google.com"

# 测试超时设置
ZSH_NETWORK_STATUS_PROMPT_TIMEOUT=1
echo "短超时测试 (1秒): $(_zsh_network_status_check_connectivity && echo '成功' || echo '失败')"

# 恢复默认超时
ZSH_NETWORK_STATUS_PROMPT_TIMEOUT=2
```

### 1.5 缓存机制测试

```bash
# 清除缓存
rm -f "$_ZSH_NETWORK_STATUS_CACHE_FILE"

# 第一次调用 - 应该执行网络请求
echo "第一次状态检查: $(_zsh_network_status_get_status)"

# 第二次调用 - 应该使用缓存
echo "第二次状态检查 (使用缓存): $(_zsh_network_status_get_status)"

# 检查缓存文件
echo "缓存文件存在: $(test -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" && echo '是' || echo '否')"
echo "缓存内容: $(cat "$_ZSH_NETWORK_STATUS_CACHE_FILE" 2>/dev/null || echo '无法读取')"

# 测试缓存过期 (通过修改文件时间)
if [[ -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" ]]; then
    # 将缓存文件时间设置为 10 分钟前
    touch -t $(date -d '10 minutes ago' +%Y%m%d%H%M 2>/dev/null || date -r $(($(date +%s) - 600)) +%Y%m%d%H%M) "$_ZSH_NETWORK_STATUS_CACHE_FILE"
    echo "缓存过期测试: $(_zsh_network_status_get_status)"
fi
```

## 2. 提示符显示测试

### 2.1 右侧提示符测试 (RPROMPT)

```bash
# 设置为右侧显示
export ZSH_NETWORK_STATUS_PROMPT_SIDE="RPROMPT"
source ./zsh-network-status-prompt.plugin.zsh

# 触发 precmd 函数来更新提示符
_zsh_network_status_precmd

# 显示当前 RPROMPT
echo "RPROMPT 内容: '$RPROMPT'"
```

### 2.2 左侧提示符测试 (PROMPT)

```bash
# 备份原始 PROMPT
ORIGINAL_PROMPT="$PROMPT"

# 设置为左侧显示
export ZSH_NETWORK_STATUS_PROMPT_SIDE="PROMPT"
source ./zsh-network-status-prompt.plugin.zsh

# 触发 precmd 函数
_zsh_network_status_precmd

# 显示当前 PROMPT
echo "PROMPT 内容: '$PROMPT'"

# 测试重复添加问题
_zsh_network_status_precmd
echo "第二次调用后的 PROMPT: '$PROMPT'"

# 恢复原始 PROMPT
PROMPT="$ORIGINAL_PROMPT"
```

## 3. 综合场景测试

### 3.1 完整状态组合测试

```bash
# 测试函数：显示完整状态
test_full_status() {
    local scenario="$1"
    echo "=== $scenario ==="
    echo "提示符内容: $(_zsh_network_status_build_prompt)"
    echo ""
}

# 场景 1: 网络正常，无代理
unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
rm -f "$_ZSH_NETWORK_STATUS_CACHE_FILE"
test_full_status "网络正常，无代理"

# 场景 2: 网络正常，有代理
export http_proxy="http://127.0.0.1:8080"
rm -f "$_ZSH_NETWORK_STATUS_CACHE_FILE"
test_full_status "网络正常，有代理"

# 场景 3: 网络异常，无代理
unset http_proxy
ZSH_NETWORK_STATUS_PROMPT_HOST="invalid-host.com"
rm -f "$_ZSH_NETWORK_STATUS_CACHE_FILE"
test_full_status "网络异常，无代理"

# 场景 4: 网络异常，有代理
export https_proxy="https://127.0.0.1:8080"
test_full_status "网络异常，有代理"

# 恢复设置
unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
ZSH_NETWORK_STATUS_PROMPT_HOST="www.google.com"
```

### 3.2 手动刷新功能测试

```bash
# 创建缓存
_zsh_network_status_get_status >/dev/null

# 检查缓存是否存在
echo "刷新前缓存存在: $(test -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" && echo '是' || echo '否')"

# 执行手动刷新
zsh_network_status_refresh

# 检查缓存是否被清除
echo "刷新后缓存存在: $(test -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" && echo '是' || echo '否')"
```

## 4. 性能测试

### 4.1 响应时间测试

```bash
# 测试缓存命中时的响应时间
echo "=== 性能测试 ==="

# 确保有缓存
_zsh_network_status_get_status >/dev/null

# 测试缓存命中性能
time_start=$(date +%s.%N)
for i in {1..10}; do
    _zsh_network_status_get_status >/dev/null
done
time_end=$(date +%s.%N)
echo "10次缓存命中耗时: $(echo "$time_end - $time_start" | bc)秒"

# 测试提示符构建性能
time_start=$(date +%s.%N)
for i in {1..10}; do
    _zsh_network_status_build_prompt >/dev/null
done
time_end=$(date +%s.%N)
echo "10次提示符构建耗时: $(echo "$time_end - $time_start" | bc)秒"
```

## 5. 配置选项测试

### 5.1 测试所有配置变量

```bash
# 测试自定义主机
export ZSH_NETWORK_STATUS_PROMPT_HOST="www.cloudflare.com"
echo "自定义主机测试: $(_zsh_network_status_check_connectivity && echo '成功' || echo '失败')"

# 测试自定义超时
export ZSH_NETWORK_STATUS_PROMPT_TIMEOUT=5
echo "自定义超时 (5秒)"

# 测试自定义缓存时间
export ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION=60
echo "自定义缓存时间 (60秒)"

# 恢复默认值
unset ZSH_NETWORK_STATUS_PROMPT_HOST
unset ZSH_NETWORK_STATUS_PROMPT_TIMEOUT
unset ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION
```

## 6. 清理测试环境

```bash
# 清理函数
cleanup_test() {
    # 清除所有相关环境变量
    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
    unset ZSH_NETWORK_STATUS_PROMPT_HOST
    unset ZSH_NETWORK_STATUS_PROMPT_TIMEOUT
    unset ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION
    unset ZSH_NETWORK_STATUS_PROMPT_SIDE
    
    # 清除缓存文件
    rm -f "$_ZSH_NETWORK_STATUS_CACHE_FILE"
    
    # 清理 hook
    if command -v add-zsh-hook >/dev/null 2>&1; then
        add-zsh-hook -d precmd _zsh_network_status_precmd 2>/dev/null || true
    fi
    
    echo "测试环境已清理"
}

# 运行清理
cleanup_test
```

## 7. 自动化测试脚本

运行上述所有测试的完整脚本，可以保存为 `run_tests.sh`：

```bash
#!/bin/zsh

echo "开始 Zsh 网络状态提示插件测试..."
echo "=================================="

# 加载插件
source ./zsh-network-status-prompt.plugin.zsh

# 运行所有测试...
# (包含上述所有测试代码)

echo "=================================="
echo "测试完成！"
```

记得给测试脚本执行权限：
```bash
chmod +x run_tests.sh
```
