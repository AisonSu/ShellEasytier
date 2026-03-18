#!/bin/sh
# Copyright (C) ShellEasytier
# 中继服务器菜单

[ -n "$__IS_MODULE_5_RELAY_LOADED" ] && return
__IS_MODULE_5_RELAY_LOADED=1

load_lang 5_relay
load_lang common

RELAYS_CFG="$EASYDIR/configs/relays.cfg"

# 确保配置文件存在
[ -f "$RELAYS_CFG" ] || touch "$RELAYS_CFG"

# 查看中继服务器
list_relays() {
    comp_box "$RELAY_CURRENT"

    # 公共中继状态
    if [ "$EASY_PUBLIC_RELAY" != "0" ]; then
        content_line "\033[32m$RELAY_CURRENT_PUBLIC\033[0m"
    else
        content_line "\033[31mPublic Relays: Disabled\033[0m"
    fi

    separator_line "-"

    if [ ! -s "$RELAYS_CFG" ]; then
        content_line "$RELAY_CURRENT_EMPTY"
    else
        i=1
        while IFS= read -r relay; do
            [ -n "$relay" ] && content_line "$i) $relay"
            i=$((i + 1))
        done < "$RELAYS_CFG"
    fi
    separator_line "="
    sleep 1
}

# 添加中继服务器
add_relay() {
    comp_box "$RELAY_ADD_TITLE" \
        "$RELAY_DESC" \
        "$RELAY_INPUT_EXAMPLE"
    separator_line "-"
    content_line "$RELAY_INPUT_ADDRESS"
    separator_line "="
    read -r -p "> " address

    if [ -z "$address" ]; then
        cancel_back
        return
    fi

    if echo "$address" | grep -qE '^(tcp|udp|ws|wss|quic)://'; then
        echo "$address" >> "$RELAYS_CFG"
        msg_alert "\033[32m$RELAY_ADD_OK\033[0m"
    else
        msg_alert "\033[31m$RELAY_ADD_FAIL\033[0m"
    fi
}

# 删除中继服务器
del_relay() {
    comp_box "$RELAY_CURRENT"

    if [ ! -s "$RELAYS_CFG" ]; then
        content_line "$RELAY_CURRENT_EMPTY"
        separator_line "="
        sleep 1
        return
    fi

    i=1
    while IFS= read -r relay; do
        [ -n "$relay" ] && content_line "$i) $relay"
        i=$((i + 1))
    done < "$RELAYS_CFG"
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
        sed -i "${num}d" "$RELAYS_CFG"
        msg_alert "\033[32m$RELAY_DEL_OK\033[0m"
    else
        errornum
    fi
}

# 设置公共中继
set_public_relay() {
    comp_box "$RELAY_PUBLIC_ENABLE"
    content_line "$RELAY_PUBLIC_DESC"
    btm_box "1) $RELAY_PUBLIC_ENABLE" \
        "2) $RELAY_PUBLIC_DISABLE" \
        "0) $COMMON_BACK"
    read -r -p "$COMMON_INPUT> " res

    case "$res" in
    1)
        EASY_PUBLIC_RELAY=1
        setconfig EASY_PUBLIC_RELAY 1
        # 删除禁用标记
        sed -i '/^no_tlp$/d' "$RELAYS_CFG" 2>/dev/null
        msg_alert "\033[32m$RELAY_PUBLIC_ENABLE\033[0m"
        ;;
    2)
        EASY_PUBLIC_RELAY=0
        setconfig EASY_PUBLIC_RELAY 0
        msg_alert "\033[33m$RELAY_PUBLIC_DISABLE\033[0m"
        ;;
    esac
}

# 中继服务器菜单
relay_menu() {
    while true; do
        relay_count=$(grep -c '^' "$RELAYS_CFG" 2>/dev/null || echo 0)

        comp_box "\033[30;47m$RELAY_MENU_TITLE\033[0m" \
            "$RELAY_MENU_DESC"
        content_line "1) $RELAY_MENU_LIST"
        content_line "2) $RELAY_MENU_ADD"
        content_line "3) $RELAY_MENU_DEL"
        content_line "4) $RELAY_MENU_PUBLIC"
        btm_box "" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " num

        case "$num" in
        "" | 0)
            break
            ;;
        1)
            list_relays
            ;;
        2)
            add_relay
            ;;
        3)
            del_relay
            ;;
        4)
            set_public_relay
            ;;
        *)
            errornum
            ;;
        esac
    done
}
