#!/bin/sh
# Copyright (C) ShellEasytier
# 网络配置菜单

[ -n "$__IS_MODULE_2_NETWORK_LOADED" ] && return
__IS_MODULE_2_NETWORK_LOADED=1

load_lang 2_network
load_lang common

# 验证IP地址
validate_ip() {
    echo "$1" | awk -F'.' '
    /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/ {
        for(i=1; i<=4; i++) {
            if($i < 0 || $i > 255) exit 1
        }
        exit 0
    }
    { exit 1 }
    '
}

# 验证端口号
validate_port() {
    [ "$1" -ge 1 ] && [ "$1" -le 65535 ] 2>/dev/null
}

# 设置虚拟IP
set_ipv4() {
    comp_box "$NET_CURRENT_CONFIG"
    content_line "$NET_CURRENT_IPV4 ${EASY_IPV4:-$COMMON_UNSET}"
    separator_line "-"
    content_line "$NET_INPUT_IPV4"
    separator_line "="
    read -r -p "> " ipv4

    if [ -z "$ipv4" ]; then
        cancel_back
        return
    fi

    if validate_ip "$ipv4"; then
        EASY_IPV4="$ipv4"
        setconfig EASY_IPV4 "$EASY_IPV4"
        msg_alert "\033[32m$NET_SET_OK\033[0m"
    else
        msg_alert "\033[31m$NET_IPV4_INVALID\033[0m"
    fi
}

# 设置DHCP模式
set_dhcp() {
    comp_box "$NET_DHCP_DESC"
    content_line "Current: ${EASY_DHCP:+Enabled}${EASY_DHCP:-Disabled}"
    btm_box "1) $NET_DHCP_ENABLE" \
        "2) $NET_DHCP_DISABLE" \
        "0) $COMMON_BACK"
    read -r -p "$COMMON_INPUT> " res

    case "$res" in
    1)
        EASY_DHCP=1
        setconfig EASY_DHCP 1
        msg_alert "\033[32mDHCP enabled\033[0m"
        ;;
    2)
        EASY_DHCP=""
        delconfig EASY_DHCP
        msg_alert "\033[33mDHCP disabled, please set static IP\033[0m"
        ;;
    esac
}

# 设置网络名称
set_network_name() {
    comp_box "$NET_CURRENT_NETWORK ${EASY_NETWORK_NAME:-$COMMON_UNSET}"
    separator_line "-"
    content_line "$NET_INPUT_NETWORK_NAME"
    separator_line "="
    read -r -p "> " name

    if [ -z "$name" ]; then
        cancel_back
        return
    fi

    EASY_NETWORK_NAME="$name"
    setconfig EASY_NETWORK_NAME "$EASY_NETWORK_NAME"
    msg_alert "\033[32m$NET_SET_OK\033[0m"
}

# 设置网络密钥
set_network_secret() {
    comp_box "$NET_CURRENT_SECRET ${EASY_NETWORK_SECRET:+$COMMON_SET}${EASY_NETWORK_SECRET:-$COMMON_UNSET}"
    separator_line "-"
    content_line "$NET_INPUT_NETWORK_SECRET"
    separator_line "="
    read -r -p "> " secret

    if [ -z "$secret" ]; then
        delconfig EASY_NETWORK_SECRET
        EASY_NETWORK_SECRET=""
        msg_alert "\033[33mNetwork secret cleared\033[0m"
    else
        EASY_NETWORK_SECRET="$secret"
        setconfig EASY_NETWORK_SECRET "$EASY_NETWORK_SECRET"
        msg_alert "\033[32m$NET_SET_OK\033[0m"
    fi
}

# 设置监听端口
set_listen_port() {
    comp_box "$NET_CURRENT_PORT ${EASY_PORT:-11010}"
    separator_line "-"
    content_line "$NET_INPUT_PORT"
    separator_line "="
    read -r -p "> " port

    if [ -z "$port" ]; then
        cancel_back
        return
    fi

    if validate_port "$port"; then
        EASY_PORT="$port"
        setconfig EASY_PORT "$EASY_PORT"
        msg_alert "\033[32m$NET_SET_OK\033[0m"
    else
        msg_alert "\033[31m$NET_PORT_INVALID\033[0m"
    fi
}

# 配置模式常量
CONFIG_MODE_LOCAL="local"
CONFIG_MODE_REMOTE="remote"

# 获取当前配置模式
get_config_mode() {
    if [ -n "$EASY_CONFIG_SERVER" ]; then
        echo "$CONFIG_MODE_REMOTE"
    else
        echo "$CONFIG_MODE_LOCAL"
    fi
}

# 显示配置模式说明
show_config_mode_help() {
    comp_box "配置模式说明"
    separator_line "-"
    content_line "\033[36m本地配置模式:\033[0m"
    content_line "  使用本地设置的参数启动 EasyTier"
    content_line "  可配置: IP、网络名称、密钥、端口等"
    separator_line "-"
    content_line "\033[36mConfig-Server 模式:\033[0m"
    content_line "  从远程 Config-Server 获取配置"
    content_line "  本地配置将被忽略，由服务器统一管理"
    separator_line "="
    content_line "按回车键继续..."
    read -r
}

# 切换配置模式
switch_config_mode() {
    current_mode=$(get_config_mode)

    comp_box "切换配置模式"
    separator_line "-"
    content_line "当前模式: \033[36m${current_mode}\033[0m"
    separator_line "-"
    content_line "1) 本地配置模式"
    content_line "2) Config-Server 模式"
    content_line "h) 查看模式说明"
    content_line "0) 返回"
    separator_line "="
    read -r -p "> " choice

    case "$choice" in
    1)
        if [ "$current_mode" = "$CONFIG_MODE_REMOTE" ]; then
            delconfig EASY_CONFIG_SERVER
            EASY_CONFIG_SERVER=""
            msg_alert "\033[32m已切换到本地配置模式\033[0m"
        else
            msg_alert "已经是本地配置模式"
        fi
        ;;
    2)
        set_config_server
        ;;
    h|H)
        show_config_mode_help
        switch_config_mode
        ;;
    esac
}

# 设置 Config-Server
set_config_server() {
    comp_box "Config-Server 模式"
    separator_line "-"
    content_line "输入 Config-Server 地址"
    content_line "格式: http://IP:端口 或 https://域名"
    content_line "示例: http://192.168.1.100:8080"
    separator_line "-"
    content_line "\033[33m注意: 启用后将使用远程配置，忽略本地设置\033[0m"
    separator_line "="
    read -r -p "> " server

    if [ -z "$server" ]; then
        cancel_back
        return
    fi

    # 简单验证 URL 格式
    if echo "$server" | grep -qE '^https?://.+'; then
        EASY_CONFIG_SERVER="$server"
        setconfig EASY_CONFIG_SERVER "$EASY_CONFIG_SERVER"
        msg_alert "\033[32m已切换到 Config-Server 模式\033[0m"
        content_line "服务器: $server"
        content_line "\033[33m本地配置已禁用\033[0m"
        sleep 1
    else
        msg_alert "\033[31m地址格式错误，应以 http:// 或 https:// 开头\033[0m"
    fi
}

# 设置RPC端口
set_rpc_port() {
    comp_box "$NET_CURRENT_RPC ${EASY_RPC_PORT:-15888}"
    separator_line "-"
    content_line "$NET_INPUT_RPC_PORT"
    separator_line "="
    read -r -p "> " port

    if [ -z "$port" ]; then
        cancel_back
        return
    fi

    if validate_port "$port"; then
        EASY_RPC_PORT="$port"
        setconfig EASY_RPC_PORT "$EASY_RPC_PORT"
        msg_alert "\033[32m$NET_SET_OK\033[0m"
    else
        msg_alert "\033[31m$NET_PORT_INVALID\033[0m"
    fi
}

# 网络配置菜单
network_menu() {
    while true; do
        # 获取当前配置模式
        current_mode=$(get_config_mode)

        comp_box "\033[30;47m$NET_MENU_TITLE\033[0m" \
            "$NET_MENU_DESC"

        # 显示当前配置模式
        if [ "$current_mode" = "$CONFIG_MODE_REMOTE" ]; then
            content_line "\033[33m【Config-Server 模式】\033[0m"
            content_line "  服务器: \033[36m${EASY_CONFIG_SERVER}\033[0m"
            separator_line "-"
            content_line "\033[90m(本地配置已禁用)\033[0m"
            separator_line "-"
            content_line "1) \033[90m虚拟IP\033[0m"
            content_line "2) \033[90mDHCP\033[0m"
            content_line "3) \033[90m网络名称\033[0m"
            content_line "4) \033[90m网络密钥\033[0m"
            content_line "5) \033[90m监听端口\033[0m"
            content_line "6) \033[90mRPC端口\033[0m"
        else
            content_line "\033[32m【本地配置模式】\033[0m"
            separator_line "-"
            content_line "1) $NET_MENU_IPV4\t\033[36m${EASY_IPV4:-$COMMON_UNSET}\033[0m"
            content_line "2) $NET_MENU_DHCP\t\033[36m${EASY_DHCP:+Enabled}${EASY_DHCP:-Disabled}\033[0m"
            content_line "3) $NET_MENU_NETWORK_NAME\t\033[36m${EASY_NETWORK_NAME:-$COMMON_UNSET}\033[0m"
            content_line "4) $NET_MENU_NETWORK_SECRET\t\033[36m${EASY_NETWORK_SECRET:+$COMMON_SET}${EASY_NETWORK_SECRET:-$COMMON_UNSET}\033[0m"
            content_line "5) $NET_MENU_PORT\t\033[36m${EASY_PORT:-11010}\033[0m"
            content_line "6) $NET_MENU_RPC_PORT\t\033[36m${EASY_RPC_PORT:-15888}\033[0m"
        fi

        separator_line "="
        content_line "7) 切换配置模式\t\033[36m${current_mode}\033[0m"
        btm_box "" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " num

        case "$num" in
        "" | 0)
            break
            ;;
        1)
            if [ "$current_mode" = "$CONFIG_MODE_LOCAL" ]; then
                set_ipv4
            else
                msg_alert "\033[33mConfig-Server 模式下禁用本地配置\033[0m"
            fi
            ;;
        2)
            if [ "$current_mode" = "$CONFIG_MODE_LOCAL" ]; then
                set_dhcp
            else
                msg_alert "\033[33mConfig-Server 模式下禁用本地配置\033[0m"
            fi
            ;;
        3)
            if [ "$current_mode" = "$CONFIG_MODE_LOCAL" ]; then
                set_network_name
            else
                msg_alert "\033[33mConfig-Server 模式下禁用本地配置\033[0m"
            fi
            ;;
        4)
            if [ "$current_mode" = "$CONFIG_MODE_LOCAL" ]; then
                set_network_secret
            else
                msg_alert "\033[33mConfig-Server 模式下禁用本地配置\033[0m"
            fi
            ;;
        5)
            if [ "$current_mode" = "$CONFIG_MODE_LOCAL" ]; then
                set_listen_port
            else
                msg_alert "\033[33mConfig-Server 模式下禁用本地配置\033[0m"
            fi
            ;;
        6)
            if [ "$current_mode" = "$CONFIG_MODE_LOCAL" ]; then
                set_rpc_port
            else
                msg_alert "\033[33mConfig-Server 模式下禁用本地配置\033[0m"
            fi
            ;;
        7)
            switch_config_mode
            ;;
        *)
            errornum
            ;;
        esac
    done
}
