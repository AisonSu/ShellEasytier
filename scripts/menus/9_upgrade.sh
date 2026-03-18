#!/bin/sh
# Copyright (C) ShellEasytier
# 更新与支持菜单

[ -n "$__IS_MODULE_9_UPGRADE_LOADED" ] && return
__IS_MODULE_9_UPGRADE_LOADED=1

load_lang common

UPGRADE_MENU_TITLE="更新与支持"
UPGRADE_MENU_DESC="更新 EasyTier 核心和脚本"

UPGRADE_CORE="更新 EasyTier 核心"
UPGRADE_SCRIPT="更新 ShellEasytier 脚本"
UPGRADE_CHECK="检查更新"
UPGRADE_CURRENT_VERSION="当前版本"
UPGRADE_LATEST_VERSION="最新版本"
UPGRADE_DOWNLOADING="正在下载..."
UPGRADE_SUCCESS="更新成功！"
UPGRADE_FAILED="更新失败！"

UPGRADE_ABOUT="关于"
UPGRADE_VERSION="版本"
UPGRADE_AUTHOR="作者"
UPGRADE_LICENSE="许可证"
UPGRADE_THANKS="感谢使用 ShellEasytier！"

# 检查 EasyTier 版本
check_core_version() {
    if [ -x "$EASYDIR/bin/easytier-core" ]; then
        current_version=$("$EASYDIR/bin/easytier-core" --version 2>/dev/null | head -1)
        echo "${current_version:-Unknown}"
    else
        echo "Not installed"
    fi
}

# 更新 EasyTier 核心
upgrade_core() {
    comp_box "$UPGRADE_CORE"
    content_line "$UPGRADE_CURRENT_VERSION: $(check_core_version)"
    separator_line "-"
    content_line "$UPGRADE_DOWNLOADING"
    separator_line "="

    if download_easytier; then
        # 如果正在运行，重启服务
        if is_running; then
            restart_easytier
        fi
        msg_alert "\033[32m$UPGRADE_SUCCESS\033[0m"
    else
        msg_alert "\033[31m$UPGRADE_FAILED\033[0m"
    fi
}

# 关于信息
show_about() {
    comp_box "\033[30;47m$UPGRADE_ABOUT\033[0m"
    content_line "$UPGRADE_VERSION: $(cat "$EASYDIR/version" 2>/dev/null)"
    content_line "EasyTier $(check_core_version)"
    separator_line "-"
    content_line "ShellEasytier - EasyTier Client for Routers"
    content_line "A user-friendly shell script for managing EasyTier"
    content_line "on embedded devices like Xiaomi routers."
    separator_line "-"
    content_line "$UPGRADE_THANKS"
    separator_line "="
    sleep 1
}

# 更新菜单
upgrade_menu() {
    while true; do
        comp_box "\033[30;47m$UPGRADE_MENU_TITLE\033[0m" \
            "$UPGRADE_MENU_DESC"
        content_line "1) $UPGRADE_CORE"
        content_line "   Current: $(check_core_version)"
        content_line "2) $UPGRADE_ABOUT"
        btm_box "" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " num

        case "$num" in
        "" | 0)
            break
            ;;
        1)
            upgrade_core
            ;;
        2)
            show_about
            ;;
        *)
            errornum
            ;;
        esac
    done
}
