[ -n "$__IS_LIB_START_WAIT" ] && return
__IS_LIB_START_WAIT=1

. "$APPDIR/scripts/libs/health_check.sh"

start_wait() {
    i=1
    while [ "$i" -le 30 ]; do
        sleep 1
        service_is_ready && return 0
        i=$((i + 1))
    done
    return 1
}
