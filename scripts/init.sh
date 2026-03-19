#!/bin/sh
# Copyright (C) ShellEasytier
# 初始化脚本

# 检测系统类型
systype=""
# 小米路由器（优先检测特有的 crontab 路径）
[ -f "/data/etc/crontabs/root" ] && systype=mi_snapshot
# Padavan
[ -z "$systype" ] && [ -f "/etc/storage/started_script.sh" ] && {
    systype=Padavan
    initdir='/etc/storage/started_script.sh'
}
# ASUS（只在未检测到时）
[ -z "$systype" ] && [ -d "/jffs" ] && {
    systype=asusrouter
    [ -f "/jffs/.asusrouter" ] && initdir='/jffs/.asusrouter'
    [ -d "/jffs/scripts" ] && initdir='/jffs/scripts/nat-start'
    nvram set jffs2_scripts="1"
    nvram commit
}
# ng_snapshot
[ -z "$systype" ] && [ -w "/var/mnt/cfg/firewall" ] && systype=ng_snapshot

# OpenWrt
[ -z "$systype" ] && [ -f "/etc/rc.common" ] && [ "$(cat /proc/1/comm 2>/dev/null)" = "procd" ] && systype=openwrt

# 容器环境检测（只在未检测到特定系统时）
[ -z "$systype" ] && {
    if grep -qE '/(docker|lxc|kubepods|crio|containerd)/' /proc/1/cgroup 2>/dev/null || [ -f /run/.containerenv ] || [ -f /.dockerenv ]; then
        systype='container'
    fi
}

# 设置安装目录
[ "$systype" = 'container' ] && EASYDIR='/etc/ShellEasytier'
[ "$systype" = 'openwrt' ] && EASYDIR='/etc/shelleasytier/ShellEasytier'
[ -z "$EASYDIR" ] && [ -d /data/ShellEasytier ] && EASYDIR='/data/ShellEasytier'
[ -z "$EASYDIR" ] && [ -d /etc/shelleasytier/ShellEasytier ] && EASYDIR='/etc/shelleasytier/ShellEasytier'
[ -z "$EASYDIR" ] && EASYDIR='/data/ShellEasytier'

# 创建目录
mkdir -p "$EASYDIR"

# 配置文件路径
CFG_PATH="$EASYDIR"/configs/ShellEasytier.cfg
. "$EASYDIR"/scripts/libs/set_config.sh
. "$EASYDIR"/scripts/libs/set_profile.sh

# 初始化配置目录
mkdir -p "$EASYDIR"/configs
[ -f "$CFG_PATH" ] || echo '# ShellEasytier Configuration File' > "$CFG_PATH"

# 检测并设置启动方式
[ -w /usr/lib/systemd/system ] && sysdir=/usr/lib/systemd/system
[ -w /etc/systemd/system ] && sysdir=/etc/systemd/system

if [ -f /etc/rc.common -a "$(cat /proc/1/comm)" = "procd" ]; then
    # OpenWrt procd
    cp -f "$EASYDIR"/starts/shelleasytier.procd /etc/init.d/shelleasytier 2>/dev/null
    chmod 755 /etc/init.d/shelleasytier 2>/dev/null
elif [ -n "$sysdir" -a "$USER" = "root" -a "$(cat /proc/1/comm)" = "systemd" ]; then
    # systemd
    mv -f "$EASYDIR"/starts/shelleasytier.service "$sysdir"/shelleasytier.service 2>/dev/null
    sed -i "s%/etc/ShellEasytier%$EASYDIR%g" "$sysdir"/shelleasytier.service 2>/dev/null
    systemctl daemon-reload 2>/dev/null
elif rc-status -r >/dev/null 2>&1; then
    # OpenRC
    mv -f "$EASYDIR"/starts/shelleasytier.openrc /etc/init.d/shelleasytier 2>/dev/null
    chmod 755 /etc/init.d/shelleasytier 2>/dev/null
fi

# 清理启动文件
rm -rf "$EASYDIR"/starts/shelleasytier.procd
rm -rf "$EASYDIR"/starts/shelleasytier.service
rm -rf "$EASYDIR"/starts/shelleasytier.openrc

# 设置默认语言
[ -f "$EASYDIR"/configs/i18n.cfg ] || echo "chs" > "$EASYDIR"/configs/i18n.cfg

# 批量授权
command -v bash >/dev/null 2>&1 && shtype=bash
[ -x /bin/ash ] && shtype=ash
for file in scripts/menu.sh scripts/init.sh menus/*.sh; do
    sed -i "s|/bin/sh|/bin/$shtype|" "$EASYDIR/$file" 2>/dev/null
    chmod +x "$EASYDIR/$file" 2>/dev/null
done

# 设置版本
version=$(cat "$EASYDIR"/version 2>/dev/null)
setconfig versionsh_l "$version"

# 生成环境变量文件
[ ! -f "$EASYDIR"/configs/command.env ] && {
    echo "EASY_TMPDIR=/tmp/ShellEasytier" > "$EASYDIR"/configs/command.env
    echo "EASY_BINDIR=$EASYDIR" >> "$EASYDIR"/configs/command.env
}

# 创建必要目录
mkdir -p "$EASYDIR"/bin
mkdir -p "$EASYDIR"/configs

# 设置命令别名
case "$systype" in
mi_snapshot)
    # 小米路由器
    shell_profile=/etc/profile
    [ -f /etc/profile ] && {
        if ! grep -q "alias se=" "$shell_profile" 2>/dev/null; then
            echo "alias se='\"$EASYDIR\"/scripts/menu.sh'" >> "$shell_profile"
            echo "alias easytier='\"$EASYDIR\"/scripts/menu.sh'" >> "$shell_profile"
        fi
    }
    ;;
*)
    # 通用 Linux
    for profile in /etc/profile ~/.bashrc ~/.bash_profile; do
        [ -f "$profile" ] && {
            if ! grep -q "alias se=" "$profile" 2>/dev/null; then
                echo "alias se='\"$EASYDIR\"/scripts/menu.sh'" >> "$profile"
            fi
        }
    done
    ;;
esac

echo "ShellEasytier initialized successfully!"
echo "Use 'se' or run '$EASYDIR/scripts/menu.sh' to start."
