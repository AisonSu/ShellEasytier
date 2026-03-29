[ -n "$__IS_LIB_SET_CONFIG" ] && return
__IS_LIB_SET_CONFIG=1

setconfig() {
    [ -z "$3" ] && configpath="$APPDIR/configs/ShellEasytier.cfg" || configpath="$3"
    [ -f "$configpath" ] || touch "$configpath"
    sed -i "/^${1}=.*/d" "$configpath"
    [ -n "$2" ] && printf '%s=%s\n' "$1" "$2" >> "$configpath"
}
