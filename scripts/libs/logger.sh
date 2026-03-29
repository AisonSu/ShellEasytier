[ -n "$__IS_LIB_LOGGER" ] && return
__IS_LIB_LOGGER=1

logger() {
    log_tmpdir="${TMPDIR:-/tmp/ShellEasytier}"
    log_file="$log_tmpdir/ShellEasytier.log"
    mkdir -p "$log_tmpdir" 2>/dev/null

    [ -n "$2" ] && [ "$2" != 0 ] && printf "\033[%sm%s\033[0m\n" "$2" "$1"
    [ -z "$2" ] && printf '%s\n' "$1"

    log_text="$(date '+%Y-%m-%d_%H:%M:%S')~$1"
    echo "$log_text" >> "$log_file"
    [ "$(wc -l "$log_file" 2>/dev/null | awk '{print $1}')" -gt 199 ] && sed -i '1,20d' "$log_file"
}
