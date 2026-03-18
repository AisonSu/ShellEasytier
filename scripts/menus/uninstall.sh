#!/bin/sh
# Copyright (C) ShellEasytier
# 卸载脚本

uninstall() {
    load_lang common

    comp_box "卸载 ShellEasytier" \
        "这将删除所有文件和配置"
    btm_box "1) 确认卸载" \
        "0) 取消"
    read -r -p "$COMMON_INPUT> " res

    if [ "$res" != 1 ]; then
        cancel_back
        return
    fi

    # 停止服务
    stop_easytier 2>/dev/null

    # 取消自启动
    . "$EASYDIR"/libs/check_autostart.sh
    unset_autostart

    # 移除别名
    for profile in /etc/profile ~/.bashrc ~/.bash_profile; do
        [ -f "$profile" ] && sed -i '/ShellEasytier/d' "$profile" 2>/dev/null
        [ -f "$profile" ] && sed -i '/alias se/d' "$profile" 2>/dev/null
        [ -f "$profile" ] && sed -i '/alias easytier/d' "$profile" 2>/dev/null
    done

    # 删除目录
    rm -rf "$EASYDIR"

    msg_alert "\033[32mShellEasytier 已卸载\033[0m"
    exit 0
}
