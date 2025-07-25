# zsh-network-status-prompt.plugin.zsh
#
# Author: LLM
# License: MIT
#
# A Zsh plugin to show network and proxy status in the prompt.

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

# The host to check for network connectivity.
ZSH_NETWORK_STATUS_PROMPT_HOST=${ZSH_NETWORK_STATUS_PROMPT_HOST:-"www.google.com"}

# The timeout for the connectivity check.
ZSH_NETWORK_STATUS_PROMPT_TIMEOUT=${ZSH_NETWORK_STATUS_PROMPT_TIMEOUT:-2}

# The cache expiration time in seconds (e.g., 300 for 5 minutes).
ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION=${ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION:-300}

# Where to display the prompt ('RPROMPT' or 'PROMPT').
ZSH_NETWORK_STATUS_PROMPT_SIDE=${ZSH_NETWORK_STATUS_PROMPT_SIDE:-"RPROMPT"}

# ------------------------------------------------------------------------------
# Cache
# ------------------------------------------------------------------------------

# Cache directory
_ZSH_NETWORK_STATUS_CACHE_DIR="${ZSH_CACHE_DIR:-$HOME/.zsh-cache}"
# Cache file path
_ZSH_NETWORK_STATUS_CACHE_FILE="$_ZSH_NETWORK_STATUS_CACHE_DIR/zsh-network-status-prompt.cache"
# Proxy configuration cache file path
_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE="$_ZSH_NETWORK_STATUS_CACHE_DIR/zsh-network-status-proxy.cache"

# Ensure cache directory exists
mkdir -p "$_ZSH_NETWORK_STATUS_CACHE_DIR"
touch "$_ZSH_NETWORK_STATUS_CACHE_FILE"
touch "$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE"


# ------------------------------------------------------------------------------
# Proxy Quick Switch Functions
# ------------------------------------------------------------------------------

start_proxy() {
    export https_proxy="http://127.0.0.1:7890" \
           http_proxy="http://127.0.0.1:7890" \
           all_proxy="socks5://127.0.0.1:7890"
    echo "enable" >| "$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE"
    _zsh_network_status_check_connectivity_sync
}

end_proxy() {
    unset https_proxy http_proxy all_proxy
    echo "disable" >| "$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE"
    _zsh_network_status_check_connectivity_sync
}



# ------------------------------------------------------------------------------
# Core Functions
# ------------------------------------------------------------------------------

# Generate a simple proxy status indicator (enabled/disabled)
_zsh_network_status_get_proxy_status() {
    if [[ -n "${http_proxy}" || -n "${https_proxy}" || -n "${all_proxy}" || \
          -n "${HTTP_PROXY}" || -n "${HTTPS_PROXY}" || -n "${ALL_PROXY}" ]]; then
        echo "enabled"
    else
        echo "disabled"
    fi
}



# Check if proxy environment variables are set (case-insensitive).
_zsh_network_status_is_proxy_enabled() {
    _ZSH_NETWORK_STATUS_PROXY_HASH=$(<"$_ZSH_NETWORK_STATUS_PROXY_CACHE_FILE")
    # Use cached status instead of re-checking environment variables
    if [[ "$_ZSH_NETWORK_STATUS_PROXY_HASH" == "enabled" ]]; then
        return 0 # Proxy is enabled
    else
        return 1 # Proxy is disabled
    fi
}


# 异步检测网络连通性并写入缓存
_zsh_network_status_check_connectivity_async() {
    (_zsh_network_status_check_connectivity_sync) &
}

_zsh_network_status_check_connectivity_sync() {
    if _zsh_network_status_check_connectivity; then
        echo "online" >| "$_ZSH_NETWORK_STATUS_CACHE_FILE"
    else
        echo "offline" >| "$_ZSH_NETWORK_STATUS_CACHE_FILE"
    fi
}


# Perform the actual network connectivity check.
_zsh_network_status_check_connectivity() {
    command curl -s --head --connect-timeout "$ZSH_NETWORK_STATUS_PROMPT_TIMEOUT" "http://${ZSH_NETWORK_STATUS_PROMPT_HOST}" >/dev/null 2>&1
}

# Get the network status, using cache if available and not expired.
_zsh_network_status_get_status() {
    local last_check_time=0
    local current_time
    current_time=$(date +%s)
    local cached_status=""

    if [[ -f "$_ZSH_NETWORK_STATUS_CACHE_FILE" ]]; then
        # Get the modification time of the cache file
        if [[ "$(uname)" == "Darwin" ]]; then
            last_check_time=$(stat -f %m "$_ZSH_NETWORK_STATUS_CACHE_FILE")
        else
            last_check_time=$(stat -c %Y "$_ZSH_NETWORK_STATUS_CACHE_FILE")
        fi
        cached_status=$(<"$_ZSH_NETWORK_STATUS_CACHE_FILE")
    fi

    # If cache is expired, perform a new check
    if (( (current_time - last_check_time) > ZSH_NETWORK_STATUS_PROMPT_CACHE_EXPIRATION )) || [[ -z "$cached_status" ]]; then
        _zsh_network_status_check_connectivity_async
        if [[ -z "$cached_status" ]]; then
            echo "checking"
            return
        fi
    fi

    echo "$cached_status"
}

# ------------------------------------------------------------------------------
# Prompt Display
# ------------------------------------------------------------------------------

# Build the prompt string based on the current status.
_zsh_network_status_build_prompt() {
    local network_status
    network_status=$(_zsh_network_status_get_status)
    local proxy_indicator=""
    local color

    # Set proxy indicator
    if _zsh_network_status_is_proxy_enabled; then
        proxy_indicator=" P"
    fi

    # Set color based on status
    if [[ "$network_status" == "online" ]]; then
        color="%F{green}"
    else
        color="%F{red}"
    fi

    # Format the final string
    echo "$color net:($network_status$proxy_indicator)%f"
}

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

_zsh_network_status_prompt_init() {
    # Check dependencies
    if ! command -v curl >/dev/null 2>&1; then
        echo "zsh-network-status-prompt: Error - 'curl' command not found. Please install curl." >&2
        return 1
    fi

    # Load required zsh modules
    autoload -U add-zsh-hook

    # Initialize proxy configuration cache

    # This function will be called before each prompt is displayed
    _zsh_network_status_precmd() {
        local prompt_string
        prompt_string=$(_zsh_network_status_build_prompt)

        if [[ "$ZSH_NETWORK_STATUS_PROMPT_SIDE" == "RPROMPT" ]]; then
            RPROMPT="$prompt_string"
        else
            # For PROMPT, only add if not already present to avoid duplication
            if [[ "$PROMPT" != *"net:("* ]]; then
                PROMPT="$prompt_string $PROMPT"
            else
                # Replace existing network status in PROMPT
                PROMPT=$(echo "$PROMPT" | sed -E 's/%F\{[^}]+\} net:\([^)]+\)%f //g')
                PROMPT="$prompt_string $PROMPT"
            fi
        fi
    }

    # Add the function to the precmd hook
    add-zsh-hook precmd _zsh_network_status_precmd
}

# Run the initialization function
_zsh_network_status_prompt_init
