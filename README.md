# Zsh 网络状态提示插件

这个 Zsh 插件在您的提示符中显示当前的网络和代理状态。

## 功能特性

-   **网络连接检查**：验证与外部主机的连接（默认：`www.google.com`）。
-   **代理检测**：当设置了 `http_proxy`、`https_proxy` 或 `all_proxy` 环境变量时显示指示器。
-   **可视状态**：连接成功时显示绿色的 `net:(online)`，连接失败时显示红色的 `net:(offline)`。
-   **代理指示器**：启用代理时在状态后添加 `P`（例如：`net:(online P)`）。
-   **缓存机制**：网络状态会被缓存以防止提示符延迟。缓存默认在 5 分钟后过期。
-   **可配置**：您可以自定义检查主机、超时时间、缓存持续时间和显示位置（左侧或右侧提示符）。

## 安装

1.  **克隆仓库**：

    ```sh
    git clone https://github.com/wedaren/zsh-network-status-prompt.git ~/.oh-my-zsh/custom/plugins/zsh-network-status-prompt
    ```

    （如果您没有使用 Oh My Zsh，请将其克隆到您选择的位置，并在您的 `.zshrc` 中 `source` 插件文件。）

2.  **将插件添加到您的 `.zshrc` 文件**：

    找到 `plugins=(...)` 行，并将 `zsh-network-status-prompt` 添加到列表中。

    ```sh
    plugins=(git zsh-network-status-prompt)
    ```

3.  **重启您的 shell**：

    ```sh
    exec zsh
    ```

## 配置

您可以通过在 `.zshrc` 文件中设置以下变量来覆盖默认设置（需要在 Oh My Zsh 被加载*之前*设置）。

-   `ZSH_NETWORK_STATUS_PROMPT_HOST`：用于连接检查的主机。
    -   默认值：`www.google.com`
    -   示例：`export ZSH_NETWORK_STATUS_PROMPT_HOST="www.cloudflare.com"`

-   `ZSH_NETWORK_STATUS_PROMPT_TIMEOUT`：检查的超时时间（秒）。
    -   默认值：`2`
    -   示例：`export ZSH_NETWORK_STATUS_PROMPT_TIMEOUT=3`

-   `ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION`：缓存生存时间（秒）。
    -   默认值：`300`（5 分钟）
    -   示例：`export ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION=600`

-   `ZSH_NETWORK_STATUS_PROMPT_SIDE`：显示状态的提示符位置（`RPROMPT` 或 `PROMPT`）。
    -   默认值：`RPROMPT`
    -   示例：`export ZSH_NETWORK_STATUS_PROMPT_SIDE="PROMPT"`

## 手动刷新

要强制刷新网络状态，绕过缓存，您可以在终端中运行以下命令：

```sh
zsh_network_status_refresh
```

## 测试

项目提供了多个测试脚本来验证插件功能：

### 快速测试
```sh
./simple_test.sh
```
运行核心功能测试，验证插件是否正常工作。

### 详细测试
```sh
./test_plugin.sh
```
运行交互式测试，展示插件的各种功能和配置。

### 完整测试套件
```sh
./run_tests.sh
```
运行自动化测试套件，全面验证所有功能。

### 查看测试文档
详细的测试说明请参考 [TESTING.md](TESTING.md) 文件。

## 许可证

该项目基于 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。
