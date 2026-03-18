#!/bin/sh
# Copyright (C) ShellEasytier
# 启动/停止服务模块

[ -n "$__IS_MODULE_1_START_LOADED" ] && return
__IS_MODULE_1_START_LOADED=1

load_lang 1_start

# 检查并下载核心
check_and_download_core() {
    if [ ! -x "$EASYDIR/bin/easytier-core" ]; then
        comp_box "\033[33m$START_NO_CORE\033[0m" \
            "$START_NO_CORE_DOWNLOAD"
        btm_box "1) $COMMON_YES" \
            "0) $COMMON_NO"
        read -r -p "$COMMON_INPUT> " res
        if [ "$res" = 1 ]; then
            line_break
            separator_line "="
            content_line "$START_DOWNLOADING"
            separator_line "="
            if download_easytier; then
                msg_alert "\033[32m$START_DOWNLOAD_OK\033[0m"
                return 0
            else
                msg_alert "\033[31m$START_DOWNLOAD_FAIL\033[0m"
                return 1
            fi
        else
            return 1
        fi
    fi
    return 0
}

# 启动完成提示
startover() {
    top_box "\033[32m$START_SERVICE_OK\033[0m"
    if [ -n "$EASY_IPV4" ]; then
        content_line "Virtual IP: \033[36m$EASY_IPV4\033[0m"
    fi
    if [ -n "$EASY_NETWORK_NAME" ]; then
        content_line "Network: \033[36m$EASY_NETWORK_NAME\033[0m"
    fi
    separator_line "="
    line_break
    sleep 1
    return 0
}

# 启动核心
start_core() {
    # 检查核心
    check_and_download_core || return 1

    # 检查网络配置
    if [ -z "$EASY_NETWORK_NAME" ] && [ -z "$EASY_DHCP" ]; then
        comp_box "\033[33mNetwork not configured!\033[0m" \
            "Please configure network settings first."
        sleep 2
        return 1
    fi

    # 启动服务
    if start_easytier; then
        startover
    else
        msg_alert "\033[31m$START_SERVICE_FAIL\033[0m"
        return 1
    fi
}

# 启动服务入口
start_service() {
    start_core
}
