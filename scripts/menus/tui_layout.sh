[ -n "$__IS_MODULE_TUI_LAYOUT_LOADED" ] && return
__IS_MODULE_TUI_LAYOUT_LOADED=1

FULL_EQ='==============================================================='
FULL_DASH='---------------------------------------------------------------'

separator_line() {
    if [ "$1" = '-' ]; then
        printf '%.63s\n' "$FULL_DASH"
    else
        printf '%.63s\n' "$FULL_EQ"
    fi
}

content_line() {
    printf '%b\n' "$1"
}

line_break() {
    printf '\n'
}
