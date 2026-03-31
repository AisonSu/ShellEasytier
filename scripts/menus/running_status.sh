#!/bin/sh

[ -n "$__IS_MODULE_RUNNING_STATUS_LOADED" ] && return
__IS_MODULE_RUNNING_STATUS_LOADED=1

running_status() {
    if "$APPDIR/start.sh" status-code >/dev/null 2>&1; then
        RUN_STATUS="\033[32m运行中\033[0m"
    else
        RUN_STATUS="\033[31m未运行\033[0m"
    fi

    if "$APPDIR/start.sh" web-status-code >/dev/null 2>&1; then
        RUN_WEB_STATUS="\033[32mWeb已启动\033[0m"
    else
        RUN_WEB_STATUS="\033[33mWeb未启动\033[0m"
    fi
}
