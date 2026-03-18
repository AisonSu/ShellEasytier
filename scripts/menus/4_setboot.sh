#!/bin/sh
# Copyright (C) ShellEasytier
# 启动设置菜单

[ -n "$__IS_MODULE_4_SETBOOT_LOADED" ] && return
__IS_MODULE_4_SETBOOT_LOADED=1

load_lang 4_setboot
load_lang common

# 设置自启动
set_autostart() {
    systype=$(get_systype)

    case "$systype" in
    mi_snapshot)
        set_autostart_mi
        ;;
    openwrt)
        /etc/init.d/shelleasytier enable 2>/dev/null
        ;;
    *)
        # 通用方式
        if [ -f /etc/rc.local ]; then
            if ! grep -q "ShellEasytier" /etc/rc.local 2>/dev/null; then
                sed -i "/exit 0/i $EASYDIR/scripts/check_and_start.sh &" /etc/rc.local
            fi
        fi
        ;;
    esac

    msg_alert "\033[32m$BOOT_SET_OK\033[0m"
}

# 取消自启动
do_unset_autostart() {
    # 调用库的取消函数
    . "$EASYDIR"/scripts/libs/check_autostart.sh
    unset_autostart

    # 额外清理 OpenWrt
    [ -f /etc/init.d/shelleasytier ] && /etc/init.d/shelleeasytier disable 2>/dev/null

    msg_alert "\033[33m$BOOT_UNSET_OK\033[0m"
}

# 设置TUN模式
set_tun_mode() {
    comp_box "TUN Mode"
    content_line "TUN mode requires root privileges."
    content_line "No-TUN mode uses SOCKS5 proxy."
    btm_box "1) $BOOT_MODE_TUN" \
        "2) $BOOT_MODE_NO_TUN" \
        "0) $COMMON_BACK"
    read -r -p "$COMMON_INPUT> " res

    case "$res" in
    1)
        EASY_NO_TUN=""
        delconfig EASY_NO_TUN
        msg_alert "\033[32m$BOOT_MODE_SET: TUN\033[0m"
        ;;
    2)
        EASY_NO_TUN=1
        setconfig EASY_NO_TUN 1
        msg_alert "\033[32m$BOOT_MODE_SET: No TUN\033[0m"
        ;;
    esac
}

# 启动设置菜单
setboot_menu() {
    while true; do
        # 检查当前状态
        if check_autostart; then
            autostart_status="$BOOT_CURRENT_AUTOSTART"
        else
            autostart_status="$BOOT_CURRENT_NO_AUTOSTART"
        fi

        if [ "$EASY_NO_TUN" = "1" ]; then
            tun_status="$BOOT_CURRENT_MODE_NOTUN"
        else
            tun_status="$BOOT_CURRENT_MODE_TUN"
        fi

        comp_box "\033[30;47m$BOOT_MENU_TITLE\033[0m" \
            "$BOOT_MENU_DESC"
        content_line "1) $BOOT_MENU_AUTOSTART"
        content_line "   $autostart_status"
        separator_line "-"
        content_line "a) $BOOT_MENU_AUTOSTART_SET"
        content_line "b) $BOOT_MENU_AUTOSTART_UNSET"
        content_line "c) $BOOT_MENU_MODE"
        content_line "   $tun_status"
        btm_box "" \
            "0) $COMMON_BACK"
        read -r -p "$COMMON_INPUT> " num

        case "$num" in
        "" | 0)
            break
            ;;
        a | A)
            set_autostart
            ;;
        b | B)
            do_unset_autostart
            ;;
        c | C)
            set_tun_mode
            ;;
        1)
            # 仅显示状态
            ;;
        *)
            errornum
            ;;
        esac
    done
}
