#!/bin/sh
# Copyright (C) ShellEasytier
# 通用 UI 组件

# 消息提示框
# 用法: msg_alert [-t 秒数] "消息1" "消息2" ...
msg_alert() {
    _sleep_time=1

    if [ "$1" = "-t" ] && [ -n "$2" ]; then
        _sleep_time="$2"
        shift 2
    fi

    line_break
    separator_line "="
    for line in "$@"; do
        content_line "$line"
    done
    separator_line "="
    sleep "$_sleep_time"
}

# 完整信息框
comp_box() {
    line_break
    separator_line "="
    for line in "$@"; do
        content_line "$line"
    done
}

# 顶部信息框
top_box() {
    line_break
    separator_line "="
    for line in "$@"; do
        content_line "$line"
    done
}

# 底部信息框
btm_box() {
    for line in "$@"; do
        content_line "$line"
    done
    separator_line "="
}

# 列表框
# 参数1: 以换行分隔的列表内容
# 参数2: 附加后缀
list_box() {
    i=1
    printf '%s\n' "$1" | while IFS= read -r f; do
        content_line "$i) $f$2"
        i=$((i + 1))
    done
}

# 成功提示
common_success() {
    msg_alert "\033[32m$COMMON_SUCCESS\033[0m"
}

# 失败提示
common_failed() {
    msg_alert "\033[31m$COMMON_FAILED\033[0m"
}

# 返回上级菜单提示
common_back() {
    content_line "0) $COMMON_BACK"
    separator_line "="
}

# 错误处理
errornum() {
    msg_alert "\033[31m$COMMON_ERR_NUM\033[0m"
}

error_letter() {
    msg_alert "\033[31m$COMMON_ERR_LETTER\033[0m"
}

error_input() {
    msg_alert "\033[31m$COMMON_ERR_INPUT\033[0m"
}

error_cancel() {
    msg_alert "\033[31m$COMMON_ERR_CANCEL\033[0m"
}

cancel_back() {
    separator_line "-"
    content_line "$COMMON_CANCEL"
    sleep 1
}
