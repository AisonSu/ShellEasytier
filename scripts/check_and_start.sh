#!/bin/sh
# Copyright (C) ShellEasytier
# 检查并启动脚本（用于自启动）

# 确定安装目录
[ -d /data/ShellEasytier ] && EASYDIR=/data/ShellEasytier
[ -d /userdisk/ShellEasytier ] && EASYDIR=/userdisk/ShellEasytier
[ -d /etc/ShellEasytier ] && EASYDIR=/etc/ShellEasytier
[ -z "$EASYDIR" ] && exit 1

# 加载库
. "$EASYDIR"/libs/get_config.sh 2>/dev/null || exit 1
. "$EASYDIR"/libs/service.sh 2>/dev/null || exit 1

# 检查是否已在运行
if is_running; then
    exit 0
fi

# 启动服务
start_easytier
