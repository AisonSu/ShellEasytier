#!/bin/sh
# Copyright (C) ShellEasytier
# 对等节点管理菜单

[ -n "$__IS_MODULE_3_PEERS_LOADED" ] && return
__IS_MODULE_3_PEERS_LOADED=1

load_lang 3_peers
load_lang common

PEERS_CFG="$EASYDIR/configs/peers.cfg"

# 确保配置文件存在
[ -f "$PEERS_CFG" ] || touch "$PEERS_CFG"

# 查看节点列表
list_peers() {
    comp_box "$PEER_LIST_TITLE"

    if [ ! -s "$PEERS_CFG" ]; then
        content_line "$PEER_LIST_EMPTY"
    else
        i=1
        while IFS= read -r peer; do
            [ -n "$peer" ] && content_line "$i) $peer"
            i=$((i + 1))
        done < "$PEERS_CFG"
    fi
    separator_line "="
    sleep 1
}

# 添加节点
add_peer() {
    comp_box "$PEER_ADD_TITLE" \
        "$PEER_ADD_DESC" \
        "$PEER_ADD_EXAMPLE"
    separator_line "-"
    content_line "$PEER_INPUT_ADDRESS"
    separator_line "="
    read -r -p "> " address

    if [ -z "$address" ]; then
        cancel_back
        return
    fi

    # 简单验证地址格式
    if echo "$address" | grep -qE '^(tcp|udp|ws|wss|quic)://'; then
        echo "$address" >> "$PEERS_CFG"
        msg_alert "\033[32m$PEER_ADD_OK\033[0m"
    else
        msg_alert "\033[31m$PEER_ADD_FAIL\033[0m"
    fi
}

# 删除节点
del_peer() {
    comp_box "$PEER_LIST_TITLE"

    if [ ! -s "$PEERS_CFG" ]; then
        content_line "$PEER_LIST_EMPTY"
        separator_line "="
        sleep 1
        return
    fi

    i=1
    while IFS= read -r peer; do
        [ -n "$peer" ] && content_line "$i) $peer"
        i=$((i + 1))
    done < "$PEERS_CFG"
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
        # 删除指定行
        sed -i "${num}d" "$PEERS_CFG"
        msg_alert "\033[32m$PEER_DEL_OK\033[0m"
    else
        errornum
    fi
}

# 对等节点菜单
peers_menu() {
    while true; do
        # 计算当前节点数
        peer_count=$(grep -c '^' "$PEERS_CFG" 2>/dev/null || echo 0)

        comp_box "\033[30;47m$PEER_MENU_TITLE\033[0m" \
            "$PEER_MENU_DESC"
        content_line "1) $PEER_MENU_LIST\t\033[36m($peer_count $PEER_LIST_COUNT)\033[0m"
        content_line "2) $PEER_MENU_ADD"
        content_line "3) $PEER_MENU_DEL"
        btm_box "" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " num

        case "$num" in
        "" | 0)
            break
            ;;
        1)
            list_peers
            ;;
        2)
            add_peer
            ;;
        3)
            del_peer
            ;;
        *)
            errornum
            ;;
        esac
    done
}
