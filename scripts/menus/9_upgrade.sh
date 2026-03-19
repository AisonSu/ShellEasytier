#!/bin/sh
# Copyright (C) ShellEasytier
# 更新与支持菜单（简化版）

[ -n "$__IS_MODULE_9_UPGRADE_LOADED" ] && return
__IS_MODULE_9_UPGRADE_LOADED=1

load_lang common

UPGRADE_MENU_TITLE="更新与支持"

UPGRADE_CHECK="检查更新"
UPGRADE_UPDATE="更新系统"
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

UPGRADE_ABOUT="关于"
UPGRADE_VERSION="版本"
UPGRADE_THANKS="感谢使用 ShellEasytier！"

# 检测架构
detect_arch() {
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)     echo "x86_64" ;;
        aarch64|arm64)    echo "aarch64" ;;
        armv7l|armv7)     echo "armv7" ;;
        mips)             echo "mips" ;;
        mipsel)           echo "mipsel" ;;
        *)                echo "generic" ;;
    esac
}

# 获取最新版本
get_latest_version() {
    curl -sL --connect-timeout 5 \
        "https://api.github.com/repos/AisonSu/ShellEasytier/releases/latest" 2>/dev/null | \
        grep '"tag_name":' | head -1 | cut -d'"' -f4
}

# 检查更新
check_update() {
    comp_box "$UPGRADE_CHECKING"

    current_version=$(cat "$EASYDIR/version" 2>/dev/null)
    latest_version=$(get_latest_version)

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

# 更新系统（下载对应架构的最新包）
upgrade_system() {
    comp_box "$UPGRADE_UPDATE"
    content_line "$UPGRADE_DOWNLOADING"
    separator_line "="

    # 获取最新版本
    latest_version=$(get_latest_version)
    if [ -z "$latest_version" ] || [ "$latest_version" = "unknown" ]; then
        msg_alert "\033[31m无法获取最新版本信息\033[0m"
        return 1
    fi

    # 检测架构
    ARCH=$(detect_arch)
    content_line "检测到架构: $ARCH"
    content_line "最新版本: $latest_version"

    # 备份配置
    if [ -d "$EASYDIR/configs" ]; then
        cp -r "$EASYDIR/configs" /tmp/se_configs_backup/ 2>/dev/null
    fi

    # 下载对应架构的包
    content_line "正在下载..."
    webget /tmp/ShellEasytier_new.tar.gz \
        "https://github.com/AisonSu/ShellEasytier/releases/download/${latest_version}/ShellEasytier-${ARCH}.tar.gz" \
        echooff 2>/dev/null

    # 如果架构特定包下载失败，尝试通用包
    if [ "$result" != "200" ]; then
        content_line "尝试下载通用版本..."
        webget /tmp/ShellEasytier_new.tar.gz \
            "https://github.com/AisonSu/ShellEasytier/releases/download/${latest_version}/ShellEasytier-generic.tar.gz" \
            echooff 2>/dev/null
    fi

    if [ "$result" = "200" ]; then
        # 解压并替换
        install_dir=$(dirname "$EASYDIR")
        if tar -zxf /tmp/ShellEasytier_new.tar.gz -C "$install_dir/" 2>/dev/null; then
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

            # 检查 EasyTier 二进制
            if [ ! -f "$EASYDIR/bin/easytier-core" ]; then
                content_line "\033[33m注意: 未包含 EasyTier 二进制，请手动下载\033[0m"
            fi

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

# 查看日志
view_log() {
    log_file="$EASY_TMPDIR/easytier.log"
    if [ -f "$log_file" ]; then
        comp_box "$UPGRADE_VIEW_LOG"
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
    separator_line "-"
    content_line "ShellEasytier - EasyTier Client for Routers"
    content_line "Architecture: $(detect_arch)"
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
        current_version=$(cat "$EASYDIR/version" 2>/dev/null)

        comp_box "\033[30;47m$UPGRADE_MENU_TITLE\033[0m"
        content_line "当前版本: \033[36m${current_version:-unknown}\033[0m"
        content_line "架构: \033[36m$(detect_arch)\033[0m"
        separator_line "-"
        content_line "1) $UPGRADE_UPDATE"
        content_line "2) $UPGRADE_CHECK"
        separator_line "-"
        content_line "3) $UPGRADE_VIEW_LOG"
        content_line "4) $UPGRADE_CLEAR_LOG"
        content_line "5) $UPGRADE_RESTART_SERVICE"
        separator_line "-"
        content_line "6) $UPGRADE_ABOUT"
        btm_box "" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " num

        case "$num" in
        "" | 0)
            break
            ;;
        1)
            upgrade_system
            ;;
        2)
            check_update
            ;;
        3)
            view_log
            ;;
        4)
            clear_log
            ;;
        5)
            restart_service
            ;;
        6)
            show_about
            ;;
        *)
            errornum
            ;;
        esac
    done
}
