#!/bin/sh
# Copyright (C) ShellEasytier
# 配置读取库

# 检查配置文件
[ -f "$EASYDIR"/configs/ShellEasytier.cfg ] || {
    mkdir -p "$EASYDIR"/configs
    echo '# ShellEasytier Configuration File' > "$EASYDIR"/configs/ShellEasytier.cfg
}

# 加载配置文件
. "$EASYDIR"/configs/ShellEasytier.cfg 2>/dev/null

# 加载环境变量
[ -f "$EASYDIR"/configs/command.env ] && . "$EASYDIR"/configs/command.env 2>/dev/null

# 设置默认值
[ -z "$EASY_BINDIR" ] && EASY_BINDIR="$EASYDIR"
[ -z "$EASY_TMPDIR" ] && EASY_TMPDIR=/tmp/ShellEasytier
[ -z "$EASY_PORT" ] && EASY_PORT=11010
[ -z "$EASY_RPC_PORT" ] && EASY_RPC_PORT=15888

# 确保临时目录存在
[ -d "$EASY_TMPDIR" ] || mkdir -p "$EASY_TMPDIR"
