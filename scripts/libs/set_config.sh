#!/bin/sh
# Copyright (C) ShellEasytier
# 配置管理库

# 参数1: 变量名
# 参数2: 变量值
# 参数3: 配置文件路径(可选，默认使用主配置)
setconfig() {
    [ -z "$3" ] && configpath="$EASYDIR"/configs/ShellEasytier.cfg || configpath="${3}"
	sed -i "/^${1}=.*/d" "$configpath"
	printf '%s=%s\n' "$1" "$2" >>"$configpath"
}

# 删除配置项
# 参数1: 变量名
# 参数2: 配置文件路径(可选)
delconfig() {
    [ -z "$2" ] && configpath="$EASYDIR"/configs/ShellEasytier.cfg || configpath="${2}"
	sed -i "/^${1}=.*/d" "$configpath"
}
