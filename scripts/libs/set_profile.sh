[ -n "$__IS_LIB_SET_PROFILE" ] && return
__IS_LIB_SET_PROFILE=1

set_profile() {
    [ -z "$1" ] && return 1
    [ -f "$1" ] || touch "$1"
    [ -z "$my_alias" ] && my_alias=se

    clear_profile "$1"

    printf '\n' >> "$1"
    printf 'alias %s="sh \"%s/menu.sh\""\n' "$my_alias" "$APPDIR" >> "$1"
    printf 'export APPDIR="%s"\n' "$APPDIR" >> "$1"
    printf 'export ETDIR="%s"\n' "$APPDIR" >> "$1"

    clear_command_shims

    . "$1" >/dev/null 2>&1 || true
}

list_command_shim_names() {
    printf '%s\n' et
    printf '%s\n' easytier
    printf '%s\n' shelleasytier
    if [ -n "$my_alias" ] && [ "$my_alias" != et ] && [ "$my_alias" != easytier ] && [ "$my_alias" != shelleasytier ]; then
        printf '%s\n' "$my_alias"
    fi
}

list_command_shim_dirs() {
    for dir in /usr/bin /bin /usr/sbin /sbin /opt/bin /opt/sbin /data/usr/bin "$HOME/.local/bin"; do
        [ -n "$dir" ] || continue
        printf '%s\n' "$dir"
    done

    old_ifs=$IFS
    IFS=':'
    for dir in $PATH; do
        [ -n "$dir" ] || continue
        printf '%s\n' "$dir"
    done
    IFS=$old_ifs
}

clear_command_shims() {
    for dir in $(list_command_shim_dirs); do
        [ -d "$dir" ] || continue
        list_command_shim_names | while IFS= read -r shim_name; do
            [ -n "$shim_name" ] || continue
            shim_path="$dir/$shim_name"
            grep -q 'ShellEasytier command shim' "$shim_path" 2>/dev/null && rm -f "$shim_path"
        done
    done
}

clear_profile() {
    [ -z "$1" ] && return 1
    [ -f "$1" ] || return 0

    sed -i '/ShellEasytier\/menu\.sh/d' "$1" 2>/dev/null
    sed -i '/alias[[:space:]].*ShellEasytier/d' "$1" 2>/dev/null
    sed -i '/^alias[[:space:]]\+et=/d' "$1" 2>/dev/null
    sed -i '/^alias[[:space:]]\+se=/d' "$1" 2>/dev/null
    sed -i '/^alias[[:space:]]\+easytier=/d' "$1" 2>/dev/null
    sed -i '/^alias[[:space:]]\+shelleasytier=/d' "$1" 2>/dev/null
    sed -i '/export APPDIR=.*ShellEasytier/d' "$1" 2>/dev/null
    sed -i '/export ETDIR=.*ShellEasytier/d' "$1" 2>/dev/null
}
