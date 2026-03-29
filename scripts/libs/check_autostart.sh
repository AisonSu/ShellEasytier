[ -n "$__IS_LIB_CHECK_AUTOSTART" ] && return
__IS_LIB_CHECK_AUTOSTART=1

[ -n "$APPDIR" ] && . "$APPDIR/scripts/libs/check_cmd.sh"

check_core_autostart() {
    if [ "$start_old" = ON ]; then
        [ ! -f "$APPDIR/.dis_startup_core" ] && return 0
    elif [ -f /etc/rc.common ] && grep -q 'procd' /proc/1/comm 2>/dev/null; then
        [ -n "$(find /etc/rc.d -name '*shelleasytier' 2>/dev/null)" ] && return 0
        [ ! -f "$APPDIR/.dis_startup_core" ] && return 0
    elif ckcmd systemctl; then
        [ "$(systemctl is-enabled shelleasytier.service 2>/dev/null)" = enabled ] && return 0
    elif rc-status -r >/dev/null 2>&1; then
        rc-update show default 2>/dev/null | grep -q 'shelleasytier' && return 0
    fi
    return 1
}

check_web_autostart() {
    if [ "$start_old" = ON ]; then
        [ ! -f "$APPDIR/.dis_startup_web" ] && [ "$install_web" = ON ] && return 0
    elif [ -f /etc/rc.common ] && grep -q 'procd' /proc/1/comm 2>/dev/null; then
        [ -n "$(find /etc/rc.d -name '*shelleasytier-web' 2>/dev/null)" ] && return 0
        [ ! -f "$APPDIR/.dis_startup_web" ] && [ "$install_web" = ON ] && return 0
    elif ckcmd systemctl; then
        [ "$(systemctl is-enabled shelleasytier-web.service 2>/dev/null)" = enabled ] && return 0
    elif rc-status -r >/dev/null 2>&1; then
        rc-update show default 2>/dev/null | grep -q 'shelleasytier-web' && return 0
    fi
    return 1
}

enable_core_autostart() {
    rm -f "$APPDIR/.dis_startup_core"
    if [ "$start_old" = ON ]; then
        return 0
    elif [ -f /etc/rc.common ] && grep -q 'procd' /proc/1/comm 2>/dev/null; then
        /etc/init.d/shelleasytier enable >/dev/null 2>&1
    elif ckcmd systemctl; then
        systemctl enable shelleasytier.service >/dev/null 2>&1
    elif rc-status -r >/dev/null 2>&1; then
        rc-update add shelleasytier default >/dev/null 2>&1
    fi
}

disable_core_autostart() {
    touch "$APPDIR/.dis_startup_core"
    if [ "$start_old" = ON ]; then
        return 0
    elif [ -f /etc/rc.common ] && grep -q 'procd' /proc/1/comm 2>/dev/null; then
        /etc/init.d/shelleasytier disable >/dev/null 2>&1
    elif ckcmd systemctl; then
        systemctl disable shelleasytier.service >/dev/null 2>&1
    elif rc-status -r >/dev/null 2>&1; then
        rc-update del shelleasytier default >/dev/null 2>&1
    fi
}

enable_web_autostart() {
    rm -f "$APPDIR/.dis_startup_web"
    if [ "$start_old" = ON ]; then
        return 0
    elif [ -f /etc/rc.common ] && grep -q 'procd' /proc/1/comm 2>/dev/null; then
        /etc/init.d/shelleasytier-web enable >/dev/null 2>&1
    elif ckcmd systemctl; then
        systemctl enable shelleasytier-web.service >/dev/null 2>&1
    elif rc-status -r >/dev/null 2>&1; then
        rc-update add shelleasytier-web default >/dev/null 2>&1
    fi
}

disable_web_autostart() {
    touch "$APPDIR/.dis_startup_web"
    if [ "$start_old" = ON ]; then
        return 0
    elif [ -f /etc/rc.common ] && grep -q 'procd' /proc/1/comm 2>/dev/null; then
        /etc/init.d/shelleasytier-web disable >/dev/null 2>&1
    elif ckcmd systemctl; then
        systemctl disable shelleasytier-web.service >/dev/null 2>&1
    elif rc-status -r >/dev/null 2>&1; then
        rc-update del shelleasytier-web default >/dev/null 2>&1
    fi
}

check_autostart() {
    check_core_autostart
}

enable_autostart() {
    enable_core_autostart
}

disable_autostart() {
    disable_core_autostart
}
