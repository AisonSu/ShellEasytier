[ -n "$__IS_LIB_SET_PROFILE" ] && return
__IS_LIB_SET_PROFILE=1

set_profile() {
    [ -z "$1" ] && return 1
    [ -f "$1" ] || touch "$1"
    [ -z "$my_alias" ] && my_alias=et

    sed -i '/ShellEasytier\/menu\.sh/d' "$1" 2>/dev/null
    sed -i '/alias[[:space:]].*ShellEasytier/d' "$1" 2>/dev/null
    sed -i '/^alias[[:space:]]\+et=/d' "$1" 2>/dev/null
    sed -i '/^alias[[:space:]]\+se=/d' "$1" 2>/dev/null
    sed -i '/^alias[[:space:]]\+easytier=/d' "$1" 2>/dev/null
    sed -i '/^alias[[:space:]]\+shelleasytier=/d' "$1" 2>/dev/null
    sed -i '/export APPDIR=.*ShellEasytier/d' "$1" 2>/dev/null
    sed -i '/export ETDIR=.*ShellEasytier/d' "$1" 2>/dev/null

    printf '\n' >> "$1"
    printf 'alias et="sh \"%s/menu.sh\""\n' "$APPDIR" >> "$1"
    printf 'alias easytier="sh \"%s/menu.sh\""\n' "$APPDIR" >> "$1"
    printf 'alias shelleasytier="sh \"%s/menu.sh\""\n' "$APPDIR" >> "$1"
    if [ "$my_alias" != et ] && [ "$my_alias" != easytier ] && [ "$my_alias" != shelleasytier ]; then
        printf 'alias %s="sh \"%s/menu.sh\""\n' "$my_alias" "$APPDIR" >> "$1"
    fi
    printf 'export APPDIR="%s"\n' "$APPDIR" >> "$1"
    printf 'export ETDIR="%s"\n' "$APPDIR" >> "$1"

    . "$1" >/dev/null 2>&1 || true
}
