#!/bin/sh
# Copyright (C) ShellEasytier
# 自启动检查库

# 检查是否已设置开机启动
check_autostart() {
    # 检查小米路由器 rc.common
    if [ -f /etc/rc.common ] && grep -q "ShellEasytier" /etc/rc.common 2>/dev/null; then
        return 0
    fi
    # 检查 /data/etc/crontabs/root (小米)
    if [ -f /data/etc/crontabs/root ] && grep -q "easytier" /data/etc/crontabs/root 2>/dev/null; then
        return 0
    fi
    # 检查 /etc/init.d/
    if [ -f /etc/init.d/shelleasytier ]; then
        return 0
    fi
    return 1
}

# 获取系统类型
get_systype() {
    systype=""
    # 小米设备
    [ -f /data/etc/crontabs/root ] && systype="mi_snapshot"
    # OpenWrt
    [ -f /etc/rc.common ] && [ "$(cat /proc/1/comm)" = "procd" ] && systype="openwrt"
    # 通用 Linux
    [ -z "$systype" ] && systype="generic"
    echo "$systype"
}

# 设置自启动 (小米路由器)
set_autostart_mi() {
    # 添加到 crontab
    cron_file="/data/etc/crontabs/root"
    [ -f "$cron_file" ] || mkdir -p "$(dirname "$cron_file")"

    # 移除旧的条目
    sed -i "/easytier/d" "$cron_file"

    # 添加重启恢复任务
    echo "*/5 * * * * $EASYDIR/scripts/check_and_start.sh" >> "$cron_file"

    # 创建检查脚本
    cat > "$EASYDIR/scripts/check_and_start.sh" << 'EOF'
#!/bin/sh
# 检查 EasyTier 是否运行，如果没有则启动
if ! pidof easytier-core > /dev/null 2>&1; then
    [ -f /data/ShellEasytier/scripts/init.sh ] && . /data/ShellEasytier/scripts/init.sh
fi
EOF
    chmod +x "$EASYDIR/scripts/check_and_start.sh"

    # 添加到 rc.local 如果有
    if [ -f /etc/rc.local ]; then
        if ! grep -q "ShellEasytier" /etc/rc.local; then
            sed -i "/exit 0/i $EASYDIR/scripts/check_and_start.sh &" /etc/rc.local
        fi
    fi

    return 0
}

# 取消自启动
unset_autostart() {
    # 移除 crontab 条目
    [ -f /data/etc/crontabs/root ] && sed -i "/easytier/d" /data/etc/crontabs/root
    [ -f /etc/crontabs/root ] && sed -i "/easytier/d" /etc/crontabs/root

    # 移除 rc.local 条目
    [ -f /etc/rc.local ] && sed -i "/ShellEasytier/d" /etc/rc.local

    # 移除 init.d 脚本
    [ -f /etc/init.d/shelleasytier ] && rm -f /etc/init.d/shelleasytier

    return 0
}
