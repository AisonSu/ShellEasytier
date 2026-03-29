[ -n "$__IS_MODULE_TUI_LITE_LOADED" ] && return
__IS_MODULE_TUI_LITE_LOADED=1

separator_line() {
    [ "$1" = '-' ] && printf '%s\n' '-----------------------------------------------' || printf '%s\n' '==============================================='
}

content_line() {
    printf '%b\n' "$1"
}

line_break() {
    return 0
}
