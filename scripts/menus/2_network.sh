#!/bin/sh
# Copyright (C) ShellEasytier
# 网络配置菜单

[ -n "$__IS_MODULE_2_NETWORK_LOADED" ] && return
__IS_MODULE_2_NETWORK_LOADED=1

load_lang 2_network
load_lang common

# 验证IP地址
validate_ip() {
    echo "$1" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' > /dev/null
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
        comp_box "\033[30;47m$NET_MENU_TITLE\033[0m" \
            "$NET_MENU_DESC"
        content_line "1) $NET_MENU_IPV4\t\033[36m${EASY_IPV4:-$COMMON_UNSET}\033[0m"
        content_line "2) $NET_MENU_DHCP\t\033[36m${EASY_DHCP:+Enabled}${EASY_DHCP:-Disabled}\033[0m"
        content_line "3) $NET_MENU_NETWORK_NAME\t\033[36m${EASY_NETWORK_NAME:-$COMMON_UNSET}\033[0m"
        content_line "4) $NET_MENU_NETWORK_SECRET\t\033[36m${EASY_NETWORK_SECRET:+$COMMON_SET}${EASY_NETWORK_SECRET:-$COMMON_UNSET}\033[0m"
        content_line "5) $NET_MENU_PORT\t\033[36m${EASY_PORT:-11010}\033[0m"
        content_line "6) $NET_MENU_RPC_PORT\t\033[36m${EASY_RPC_PORT:-15888}\033[0m"
        btm_box "" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " num

        case "$num" in
        "" | 0)
            break
            ;;
        1)
            set_ipv4
            ;;
        2)
            set_dhcp
            ;;
        3)
            set_network_name
            ;;
        4)
            set_network_secret
            ;;
        5)
            set_listen_port
            ;;
        6)
            set_rpc_port
            ;;
        *)
            errornum
            ;;
        esac
    done
}
