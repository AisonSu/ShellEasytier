#!/bin/sh
# Copyright (C) ShellEasytier
# 主菜单入口

EASYDIR=$(
	cd $(dirname $0)/..
	pwd
)

CFG_PATH="$EASYDIR"/configs/ShellEasytier.cfg

# 加载执行目录，失败则初始化
. "$EASYDIR"/scripts/libs/get_config.sh 2>/dev/null
[ -z "$EASY_BINDIR" -o -z "$EASY_TMPDIR" ] && . "$EASYDIR"/scripts/init.sh >/dev/null 2>&1
[ ! -f "$EASY_TMPDIR" ] && mkdir -p "$EASY_TMPDIR"

# 通用工具
. "$EASYDIR"/scripts/libs/set_config.sh
. "$EASYDIR"/scripts/libs/web_get.sh
. "$EASYDIR"/scripts/libs/i18n.sh
. "$EASYDIR"/scripts/libs/service.sh
. "$EASYDIR"/scripts/libs/check_autostart.sh
. "$EASYDIR"/scripts/menus/tui_layout.sh
. "$EASYDIR"/scripts/menus/common.sh
. "$EASYDIR"/scripts/menus/1_start.sh

# 加载语言
load_lang common
load_lang menu

# 读取版本
version_l=$(cat "$EASYDIR/version" 2>/dev/null || echo "unknown")

# 检查是否需要重启服务
checkrestart() {
	comp_box "\033[32m$MENU_RESTART_NOTICE\033[0m"
	btm_box "1) $MENU_RESTART_NOW" \
		"0) $MENU_RESTART_LATER"
	read -r -p "$COMMON_INPUT> " res
	if [ "$res" = 1 ]; then
		start_service
	fi
}

# 获取本机IP
get_host_ip() {
	[ -z "$host" ] && host=$(ubus call network.interface.lan status 2>&1 | grep \"address\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
	[ -z "$host" ] && host=$(ip a 2>&1 | grep -w 'inet' | grep 'global' | grep 'lan' | grep -E ' 1(92|0|72)\.' | sed 's/.*inet.//g' | sed 's\/[0-9][0-9].*$//g' | head -n 1)
	[ -z "$host" ] && host=$(ip a 2>&1 | grep -w 'inet' | grep 'global' | grep -E ' 1(92|0|72)\.' | sed 's/.*inet.//g' | sed 's\/[0-9][0-9].*$//g' | head -n 1)
	[ -z "$host" ] && host='127.0.0.1'
	echo "$host"
}

# 脚本启动前检查
ckstatus() {
	version=$(cat "$EASYDIR"/version 2>/dev/null)
	[ -n "$version" ] && version_l=$version

	# 获取本机host地址
	host=$(get_host_ip)

	# 检查自启动状态
	if check_autostart; then
		auto="\033[32m$MENU_AUTOSTART_ON\033[0m"
	else
		auto="\033[31m$MENU_AUTOSTART_OFF\033[0m"
	fi

	# 检查服务运行状态
	PID=$(get_pid)
	if [ -n "$PID" ]; then
		run="\033[32m$MENU_RUN_ON\033[0m"
		uptime=$(get_uptime 2>/dev/null)
		[ -n "$uptime" ] && run="$run ($uptime)"
	else
		run="\033[31m$MENU_RUN_OFF\033[0m"
	fi

	top_box "\033[30;43m$MENU_WELCOME\033[0m\t\t  Ver: $version_l" \
		"$MENU_GITHUB\033[36;4mhttps://github.com/EasyTier/\033[0m"
	separator_line "-"
	content_line "EasyTier: $run\t  $auto"
	if [ -n "$PID" ]; then
		[ -n "$EASY_IPV4" ] && content_line "Virtual IP: \033[36m$EASY_IPV4\033[0m"
		[ -n "$EASY_NETWORK_NAME" ] && content_line "Network: \033[36m$EASY_NETWORK_NAME\033[0m"
	fi
	separator_line "="
}

# 主菜单
main_menu() {
	while true; do
		ckstatus

		btm_box "1) \033[32m$MENU_MAIN_1\033[0m"\
		"2) \033[36m$MENU_MAIN_2\033[0m"\
		"3) \033[31m$MENU_MAIN_3\033[0m"\
		"4) \033[33m$MENU_MAIN_4\033[0m"\
		"5) \033[32m$MENU_MAIN_5\033[0m"\
		"6) \033[36m$MENU_MAIN_6\033[0m"\
		"7) \033[33m$MENU_MAIN_7\033[0m"\
		"8) $MENU_MAIN_8"\
		"9) \033[32m$MENU_MAIN_9\033[0m"\
		""\
		"0) $MENU_MAIN_0"
		read -r -p "$MENU_MAIN_PROMPT" num

		case "$num" in
		"" | 0)
			line_break
			exit 0
			;;
		1)
			start_service
			line_break
			;;
		2)
			checkcfg=$(cat "$CFG_PATH" 2>/dev/null)
			. "$EASYDIR"/scripts/menus/2_network.sh && network_menu
			if [ -n "$PID" ]; then
				checkcfg_new=$(cat "$CFG_PATH" 2>/dev/null)
				[ "$checkcfg" != "$checkcfg_new" ] && checkrestart
			fi
			;;
		3)
			stop_easytier
			msg_alert "\033[31m$MENU_SERVICE_STOPPED\033[0m"
			;;
		4)
			. "$EASYDIR"/scripts/menus/4_setboot.sh && setboot_menu
			;;
		5)
			checkcfg=$(cat "$CFG_PATH" 2>/dev/null)
			. "$EASYDIR"/scripts/menus/3_peers.sh && peers_menu
			if [ -n "$PID" ]; then
				checkcfg_new=$(cat "$CFG_PATH" 2>/dev/null)
				[ "$checkcfg" != "$checkcfg_new" ] && checkrestart
			fi
			;;
		6)
			checkcfg=$(cat "$CFG_PATH" 2>/dev/null)
			. "$EASYDIR"/scripts/menus/4_proxy.sh && proxy_menu
			if [ -n "$PID" ]; then
				checkcfg_new=$(cat "$CFG_PATH" 2>/dev/null)
				[ "$checkcfg" != "$checkcfg_new" ] && checkrestart
			fi
			;;
		7)
			checkcfg=$(cat "$CFG_PATH" 2>/dev/null)
			. "$EASYDIR"/scripts/menus/5_relay.sh && relay_menu
			if [ -n "$PID" ]; then
				checkcfg_new=$(cat "$CFG_PATH" 2>/dev/null)
				[ "$checkcfg" != "$checkcfg_new" ] && checkrestart
			fi
			;;
		8)
			. "$EASYDIR"/scripts/menus/6_status.sh && status_menu
			;;
		9)
			. "$EASYDIR"/scripts/menus/9_upgrade.sh && upgrade_menu
			;;
		*)
			errornum
			;;
		esac
	done
}

# 命令行处理
case "$1" in
"" | -l)
	main_menu
	;;
-s)
	case "$2" in
	start)
		start_service
		;;
	stop)
		stop_easytier
		echo "$MENU_SERVICE_STOPPED"
		;;
	restart)
		restart_easytier
		echo "$MENU_SERVICE_RESTARTED"
		;;
	status)
		if is_running; then
			echo "EasyTier is running (PID: $(get_pid))"
		else
			echo "EasyTier is not running"
		fi
		;;
	esac
	;;
-i)
	. "$EASYDIR"/scripts/init.sh 2>/dev/null
	;;
-h | --help | *)
	comp_box "$MENU_WELCOME"
	content_line "Usage: se [option]"
	separator_line "-"
	content_line "  -l          $MENU_CLI_TEST"
	content_line "  -h          $MENU_CLI_HELP"
	content_line "  -i          $MENU_CLI_INIT"
	content_line "  -s start    $MENU_CLI_START"
	content_line "  -s stop     $MENU_CLI_STOP"
	content_line "  -s restart  $MENU_SERVICE_RESTARTED"
	content_line "  -s status   $MENU_CLI_STATUS"
	separator_line "-"
	content_line "$MENU_HELP_GITHUB\033[36mhttps://github.com/EasyTier/\033[0m"
	separator_line "="
	line_break
	;;
esac
