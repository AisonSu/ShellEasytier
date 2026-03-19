#!/bin/sh
# Copyright (C) ShellEasytier
# 服务管理库

# EasyTier PID 文件
PID_FILE="${EASY_TMPDIR:-/tmp/ShellEasytier}/easytier.pid"

# 获取 EasyTier PID
get_pid() {
    pidof easytier-core 2>/dev/null || cat "$PID_FILE" 2>/dev/null
}

# 检查服务是否运行
is_running() {
    pid=$(get_pid)
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

# 启动 EasyTier 服务
start_easytier() {
    if is_running; then
        return 0
    fi

    # 检查核心文件
    if [ ! -x "$EASYDIR/bin/easytier-core" ]; then
        return 1
    fi

    # 构建启动参数
    args=""

    # 判断配置模式：优先检查 Config-Server
    if [ -n "$EASY_CONFIG_SERVER" ]; then
        # Config-Server 模式：只使用远程配置
        args="--config-server $EASY_CONFIG_SERVER"

        # 可选：RPC 端口在两种模式下都可用
        [ -n "$EASY_RPC_PORT" ] && args="$args --rpc-portal 127.0.0.1:$EASY_RPC_PORT"

        # 可选：禁用 TUN
        [ "$EASY_NO_TUN" = "1" ] && args="$args --no-tun"
    else
        # 本地配置模式：使用所有本地参数

        # 虚拟 IP
        [ -n "$EASY_IPV4" ] && args="$args --ipv4 $EASY_IPV4"

        # DHCP 模式
        [ "$EASY_DHCP" = "1" ] && args="$args -d"

        # 网络名称和密码
        [ -n "$EASY_NETWORK_NAME" ] && args="$args -n $EASY_NETWORK_NAME"
        [ -n "$EASY_NETWORK_SECRET" ] && args="$args --network-secret $EASY_NETWORK_SECRET"

        # 对等节点
        if [ -f "$EASYDIR/configs/peers.cfg" ]; then
            while IFS= read -r peer; do
                [ -n "$peer" ] && args="$args -p $peer"
            done < "$EASYDIR/configs/peers.cfg"
        fi

        # RPC 端口
        [ -n "$EASY_RPC_PORT" ] && args="$args --rpc-portal 127.0.0.1:$EASY_RPC_PORT"

        # 监听器端口
        [ -n "$EASY_PORT" ] && args="$args -l $EASY_PORT"

        # 中继服务器
        if [ -f "$EASYDIR/configs/relays.cfg" ]; then
            while IFS= read -r relay; do
                [ -n "$relay" ] && args="$args -r $relay"
            done < "$EASYDIR/configs/relays.cfg"
        fi

        # 子网代理
        if [ -f "$EASYDIR/configs/proxy_subnets.cfg" ]; then
            while IFS= read -r subnet; do
                [ -n "$subnet" ] && args="$args --proxy-networks $subnet"
            done < "$EASYDIR/configs/proxy_subnets.cfg"
        fi

        # 禁用 TUN (如无权限)
        [ "$EASY_NO_TUN" = "1" ] && args="$args --no-tun"
    fi

    # 启动服务（使用 & 后台运行，不依赖 nohup）
    cd "$EASY_TMPDIR" || exit 1
    "$EASYDIR/bin/easytier-core" $args >> "$EASY_TMPDIR/easytier.log" 2>&1 &
    pid=$!
    echo $pid > "$PID_FILE"

    # 等待启动
    sleep 2
    if is_running; then
        return 0
    else
        return 1
    fi
}

# 停止 EasyTier 服务
stop_easytier() {
    pid=$(get_pid)
    if [ -n "$pid" ]; then
        kill "$pid" 2>/dev/null
        sleep 1
        # 强制终止
        if is_running; then
            kill -9 "$pid" 2>/dev/null
        fi
    fi
    rm -f "$PID_FILE"
}

# 重启 EasyTier 服务
restart_easytier() {
    stop_easytier
    sleep 1
    start_easytier
}

# 获取运行时长
get_uptime() {
    pid=$(get_pid)
    if [ -n "$pid" ]; then
        # 读取进程启动时间
        start_time=$(stat -c %Y /proc/$pid 2>/dev/null)
        if [ -n "$start_time" ]; then
            current_time=$(date +%s)
            uptime=$((current_time - start_time))
            # 转换为天时分格式
            days=$((uptime / 86400))
            hours=$(((uptime % 86400) / 3600))
            mins=$(((uptime % 3600) / 60))
            printf "%d天%02d:%02d" $days $hours $mins
        fi
    fi
}

# 获取连接节点数
get_peer_count() {
    if check_cmd easytier-cli; then
        "$EASYDIR/bin/easytier-cli" peer 2>/dev/null | grep -c "tcp://" || echo "0"
    else
        echo "?"
    fi
}
