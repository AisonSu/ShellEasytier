[ -n "$__IS_LIB_HEALTH_CHECK" ] && return
__IS_LIB_HEALTH_CHECK=1

. "$APPDIR/scripts/libs/check_cmd.sh"

get_rpc_port() {
    case "$rpc_portal" in
        ''|0)
            return 1
            ;;
        *:*)
            port=${rpc_portal##*:}
            ;;
        *)
            port=$rpc_portal
            ;;
    esac

    [ -n "$port" ] || return 1
    [ "$port" = 0 ] && return 1
    printf '%s\n' "$port"
}

port_is_listening() {
    port="$1"
    [ -n "$port" ] || return 1

    if ckcmd ss; then
        ss -lnt 2>/dev/null | grep -qE "[\.:]${port}[[:space:]]"
        return $?
    fi

    if ckcmd netstat; then
        netstat -ntl 2>/dev/null | grep -qE "[\.:]${port}[[:space:]]"
        return $?
    fi

    return 1
}

service_is_ready() {
    pidof easytier-core >/dev/null 2>&1 || return 1

    if [ "$et_mode" = remote ]; then
        return 0
    fi

    port=$(get_rpc_port 2>/dev/null)
    if [ -n "$port" ]; then
        port_is_listening "$port" || return 1
    fi

    return 0
}

web_is_ready() {
    pidof easytier-web-embed >/dev/null 2>&1
}
