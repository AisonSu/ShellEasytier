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
UPGRADE_CHECKING="正在检查更新..."
UPGRADE_NO_UPDATE="当前已是最新版本"
UPGRADE_UPDATE_AVAILABLE="发现新版本"
UPGRADE_VIEW_LOG="查看运行日志"
UPGRADE_CLEAR_LOG="清空日志"
UPGRADE_RESTART_SERVICE="重启服务"
UPGRADE_GITHUB="GitHub 仓库"
UPGRADE_DOCUMENTATION="使用文档"

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

# 获取 ShellEasytier 最新版本
get_latest_script_version() {
    latest=$(curl -sL --connect-timeout 5 \
        https://api.github.com/repos/AisonSu/ShellEasytier/releases/latest 2>/dev/null | \
        grep '"tag_name":' | head -1 | cut -d'"' -f4)
    echo "${latest:-unknown}"
}

# 检查更新
check_update() {
    comp_box "$UPGRADE_CHECKING"

    current_version=$(cat "$EASYDIR/version" 2>/dev/null)
    latest_version=$(get_latest_script_version)

    content_line "$UPGRADE_CURRENT_VERSION: ${current_version:-unknown}"
    content_line "$UPGRADE_LATEST_VERSION: ${latest_version:-unknown}"
    separator_line "="

    if [ "$current_version" = "$latest_version" ]; then
        content_line "\033[32m$UPGRADE_NO_UPDATE\033[0m"
    else
        content_line "\033[33m$UPGRADE_UPDATE_AVAILABLE: $latest_version\033[0m"
    fi

    sleep 2
}

# 更新 ShellEasytier 脚本
upgrade_script() {
    comp_box "$UPGRADE_SCRIPT"
    content_line "$UPGRADE_DOWNLOADING"
    separator_line "="

    # 获取最新版本号
    latest_version=$(get_latest_script_version)
    if [ "$latest_version" = "unknown" ]; then
        msg_alert "\033[31m无法获取最新版本信息\033[0m"
        return 1
    fi

    # 备份配置
    if [ -d "$EASYDIR/configs" ]; then
        cp -r "$EASYDIR/configs" /tmp/se_configs_backup/ 2>/dev/null
    fi

    # 下载指定版本
    content_line "下载版本: $latest_version"
    webget /tmp/ShellEasytier_new.tar.gz \
        "https://github.com/AisonSu/ShellEasytier/releases/download/${latest_version}/ShellEasytier.tar.gz" \
        echooff 2>/dev/null

    if [ "$result" = "200" ]; then
        # 解压并替换
        install_dir=$(dirname "$EASYDIR")
        if tar -zxf /tmp/ShellEasytier_new.tar.gz -C "$install_dir/" 2>/dev/null; then
            # 版本核对
            downloaded_version=$(cat "$EASYDIR/version" 2>/dev/null || echo "unknown")
            if [ "$downloaded_version" != "$latest_version" ]; then
                msg_alert "\033[33m版本核对警告\033[0m"
                content_line "预期版本: $latest_version"
                content_line "实际版本: $downloaded_version"
                content_line "继续安装..."
                sleep 2
            else
                content_line "\033[32m✓ 版本核对通过: $downloaded_version\033[0m"
            fi

            # 设置执行权限
            chmod +x "$EASYDIR/scripts/"*.sh 2>/dev/null
            chmod +x "$EASYDIR/scripts/libs/"*.sh 2>/dev/null
            chmod +x "$EASYDIR/scripts/menus/"*.sh 2>/dev/null

            # 恢复配置
            if [ -d /tmp/se_configs_backup ]; then
                cp -r /tmp/se_configs_backup/* "$EASYDIR/configs/" 2>/dev/null
                rm -rf /tmp/se_configs_backup
            fi
            rm -f /tmp/ShellEasytier_new.tar.gz
            msg_alert "\033[32m$UPGRADE_SUCCESS\033[0m"
            content_line "\033[33m请重新运行 se 命令以使用新版本\033[0m"
            sleep 2
        else
            msg_alert "\033[31m$UPGRADE_FAILED\033[0m"
        fi
    else
        msg_alert "\033[31m$UPGRADE_FAILED\033[0m"
        content_line "请检查网络连接"
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

# 查看日志
view_log() {
    log_file="$EASY_TMPDIR/easytier.log"
    if [ -f "$log_file" ]; then
        comp_box "$UPGRADE_VIEW_LOG"
        # 显示最后 50 行
        tail -n 50 "$log_file" 2>/dev/null | while IFS= read -r line; do
            content_line "$line"
        done
        separator_line "="
        content_line "按回车键返回..."
        read -r
    else
        msg_alert "\033[33m日志文件不存在\033[0m"
    fi
}

# 清空日志
clear_log() {
    log_file="$EASY_TMPDIR/easytier.log"
    if [ -f "$log_file" ]; then
        > "$log_file"
        msg_alert "\033[32m日志已清空\033[0m"
    else
        msg_alert "\033[33m日志文件不存在\033[0m"
    fi
}

# 重启服务
restart_service() {
    comp_box "$UPGRADE_RESTART_SERVICE"
    if is_running; then
        restart_easytier
        msg_alert "\033[32m服务已重启\033[0m"
    else
        start_easytier
        msg_alert "\033[32m服务已启动\033[0m"
    fi
}

# 关于信息
show_about() {
    comp_box "\033[30;47m$UPGRADE_ABOUT\033[0m"
    content_line "$UPGRADE_VERSION: $(cat "$EASYDIR/version" 2>/dev/null)"
    content_line "EasyTier: $(check_core_version)"
    separator_line "-"
    content_line "ShellEasytier - EasyTier Client for Routers"
    content_line "A user-friendly shell script for managing EasyTier"
    content_line "on embedded devices like Xiaomi routers."
    separator_line "-"
    content_line "$UPGRADE_GITHUB:"
    content_line "\033[36;4mhttps://github.com/AisonSu/ShellEasytier\033[0m"
    separator_line "-"
    content_line "$UPGRADE_THANKS"
    separator_line "="
    content_line "按回车键返回..."
    read -r
}

# 更新菜单
upgrade_menu() {
    while true; do
        comp_box "\033[30;47m$UPGRADE_MENU_TITLE\033[0m" \
            "$UPGRADE_MENU_DESC"
        content_line "1) $UPGRADE_CORE"
        content_line "   $UPGRADE_CURRENT_VERSION: $(check_core_version)"
        separator_line "-"
        content_line "2) $UPGRADE_SCRIPT"
        content_line "3) $UPGRADE_CHECK"
        separator_line "-"
        content_line "4) $UPGRADE_VIEW_LOG"
        content_line "5) $UPGRADE_CLEAR_LOG"
        content_line "6) $UPGRADE_RESTART_SERVICE"
        separator_line "-"
        content_line "7) $UPGRADE_ABOUT"
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
            upgrade_script
            ;;
        3)
            check_update
            ;;
        4)
            view_log
            ;;
        5)
            clear_log
            ;;
        6)
            restart_service
            ;;
        7)
            show_about
            ;;
        *)
            errornum
            ;;
        esac
    done
}
