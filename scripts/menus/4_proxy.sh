#!/bin/sh
# Copyright (C) ShellEasytier
# 子网代理菜单

[ -n "$__IS_MODULE_4_PROXY_LOADED" ] && return
__IS_MODULE_4_PROXY_LOADED=1

load_lang 4_proxy
load_lang common

PROXY_CFG="$EASYDIR/configs/proxy_subnets.cfg"

# 确保配置文件存在
[ -f "$PROXY_CFG" ] || touch "$PROXY_CFG"

# 验证子网格式
validate_subnet() {
    echo "$1" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$' > /dev/null
}

# 查看代理子网
list_proxy_subnets() {
    comp_box "$PROXY_CURRENT"

    if [ ! -s "$PROXY_CFG" ]; then
        content_line "$PROXY_CURRENT_EMPTY"
    else
        i=1
        while IFS= read -r subnet; do
            [ -n "$subnet" ] && content_line "$i) $subnet"
            i=$((i + 1))
        done < "$PROXY_CFG"
    fi

    # 显示启用状态
    if [ "$EASY_PROXY_ENABLE" = "1" ]; then
        separator_line "-"
        content_line "\033[32m$PROXY_CURRENT_ENABLED\033[0m"
    else
        separator_line "-"
        content_line "\033[31m$PROXY_CURRENT_DISABLED\033[0m"
    fi

    separator_line "="
    sleep 1
}

# 添加代理子网
add_proxy_subnet() {
    comp_box "$PROXY_ADD_TITLE" \
        "$PROXY_DESC" \
        "$PROXY_DESC_2"
    separator_line "-"
    content_line "$PROXY_INPUT_SUBNET"
    separator_line "="
    read -r -p "> " subnet

    if [ -z "$subnet" ]; then
        cancel_back
        return
    fi

    if validate_subnet "$subnet"; then
        echo "$subnet" >> "$PROXY_CFG"
        # 自动启用
        EASY_PROXY_ENABLE=1
        setconfig EASY_PROXY_ENABLE 1
        msg_alert "\033[32m$PROXY_ADD_OK\033[0m"
    else
        msg_alert "\033[31m$PROXY_ADD_FAIL\033[0m"
    fi
}

# 删除代理子网
del_proxy_subnet() {
    comp_box "$PROXY_CURRENT"

    if [ ! -s "$PROXY_CFG" ]; then
        content_line "$PROXY_CURRENT_EMPTY"
        separator_line "="
        sleep 1
        return
    fi

    i=1
    while IFS= read -r subnet; do
        [ -n "$subnet" ] && content_line "$i) $subnet"
        i=$((i + 1))
    done < "$PROXY_CFG"
    separator_line "-"
    content_line "0) $COMMON_CANCEL"
    separator_line "="

    content_line "$PEER_SELECT_DEL"
    read -r -p "> " num

    if [ "$num" = "0" ] || [ -z "$num" ]; then
        cancel_back
        return
    fi

    if [ "$num" -ge 1 ] 2>/dev/null; then
        sed -i "${num}d" "$PROXY_CFG"
        msg_alert "\033[32m$PROXY_DEL_OK\033[0m"
    else
        errornum
    fi
}

# 启用/禁用子网代理
toggle_proxy() {
    if [ "$EASY_PROXY_ENABLE" = "1" ]; then
        comp_box "$PROXY_CURRENT_ENABLED"
        content_line "$PROXY_WARN"
        btm_box "1) $PROXY_MENU_DISABLE" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " res
        if [ "$res" = 1 ]; then
            EASY_PROXY_ENABLE=""
            delconfig EASY_PROXY_ENABLE
            msg_alert "\033[33m$PROXY_DISABLE_OK\033[0m"
        fi
    else
        comp_box "$PROXY_CURRENT_DISABLED"
        content_line "$PROXY_DESC"
        btm_box "1) $PROXY_MENU_ENABLE" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " res
        if [ "$res" = 1 ]; then
            EASY_PROXY_ENABLE=1
            setconfig EASY_PROXY_ENABLE 1
            msg_alert "\033[32m$PROXY_ENABLE_OK\033[0m"
        fi
    fi
}

# 子网代理菜单
proxy_menu() {
    while true; do
        comp_box "\033[30;47m$PROXY_MENU_TITLE\033[0m" \
            "$PROXY_MENU_DESC"
        content_line "1) $PROXY_MENU_LIST"
        content_line "2) $PROXY_MENU_ADD"
        content_line "3) $PROXY_MENU_DEL"
        content_line "4) $PROXY_MENU_ENABLE/$PROXY_MENU_DISABLE"
        btm_box "" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " num

        case "$num" in
        "" | 0)
            break
            ;;
        1)
            list_proxy_subnets
            ;;
        2)
            add_proxy_subnet
            ;;
        3)
            del_proxy_subnet
            ;;
        4)
            toggle_proxy
            ;;
        *)
            errornum
            ;;
        esac
    done
}
