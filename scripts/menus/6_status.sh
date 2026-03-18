#!/bin/sh
# Copyright (C) ShellEasytier
# 状态监控菜单

[ -n "$__IS_MODULE_6_STATUS_LOADED" ] && return
__IS_MODULE_6_STATUS_LOADED=1

load_lang 6_status
load_lang common

# 查看服务状态
show_service_status() {
    comp_box "$STATUS_MENU_TITLE"

    # 服务状态
    content_line "$STATUS_SERVICE"
    if is_running; then
        PID=$(get_pid)
        content_line "  \033[32m$STATUS_RUNNING\033[0m (PID: $PID)"
        uptime=$(get_uptime 2>/dev/null)
        [ -n "$uptime" ] && content_line "  $STATUS_UPTIME: $uptime"
    else
        content_line "  \033[31m$STATUS_STOPPED\033[0m"
    fi

    separator_line "-"

    # 网络状态
    content_line "$STATUS_NETWORK"
    content_line "  $STATUS_IPV4: ${EASY_IPV4:-$COMMON_UNSET}"
    content_line "  $STATUS_NETWORK_NAME: ${EASY_NETWORK_NAME:-$COMMON_UNSET}"
    content_line "  $STATUS_LISTEN_PORT: ${EASY_PORT:-11010}"

    separator_line "-"

    # 连接状态（如果运行中）
    if is_running; then
        content_line "$STATUS_CONNECTIONS"
        # 尝试获取节点数
        if [ -x "$EASYDIR/bin/easytier-cli" ]; then
            peer_count=$("$EASYDIR/bin/easytier-cli" peer 2>/dev/null | grep -c 'peers' || echo "0")
            content_line "  $STATUS_PEERS_COUNT: $peer_count"
        else
            content_line "  $STATUS_PEERS_COUNT: Unknown (cli not found)"
        fi
    fi

    separator_line "="
    sleep 1
}

# 查看日志
view_logs() {
    LOG_FILE="${EASY_TMPDIR:-/tmp/ShellEasytier}/easytier.log"

    comp_box "$STATUS_LOG_TITLE"

    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        # 显示最后30行
        tail -n 30 "$LOG_FILE" | while IFS= read -r line; do
            # 截断长行
            if [ "${#line}" -gt 55 ]; then
                line="${line:0:55}..."
            fi
            content_line "$line"
        done
    else
        content_line "$STATUS_LOG_EMPTY"
    fi

    separator_line "="
    echo "Press Enter to continue..."
    read -r
}

# 清空日志
clear_logs() {
    LOG_FILE="${EASY_TMPDIR:-/tmp/ShellEasytier}/easytier.log"
    > "$LOG_FILE" 2>/dev/null
    msg_alert "\033[32mLogs cleared!\033[0m"
}

# 状态监控菜单
status_menu() {
    while true; do
        comp_box "\033[30;47m$STATUS_MENU_TITLE\033[0m" \
            "$STATUS_MENU_DESC"
        content_line "1) $STATUS_MENU_TITLE"
        content_line "2) $STATUS_VIEW_LOG"
        content_line "3) $STATUS_CLEAR_LOG"
        btm_box "" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " num

        case "$num" in
        "" | 0)
            break
            ;;
        1)
            show_service_status
            ;;
        2)
            view_logs
            ;;
        3)
            clear_logs
            ;;
        *)
            errornum
            ;;
        esac
    done
}
