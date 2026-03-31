#!/bin/sh

[ -z "$APPDIR" ] && APPDIR=$(
    cd "$(dirname "$0")/.."
    pwd
)
export APPDIR

. "$APPDIR/scripts/libs/get_config.sh"

msg() {
    printf '%s\n' "$*"
}

confirm_uninstall() {
    msg '-----------------------------------------------'
    msg 'ShellEasytier will be fully removed. / 即将完整卸载 ShellEasytier。'
    msg 'This removes startup hooks, aliases, services, runtime cache, and the install directory.'
    msg '将移除开机启动钩子、别名、服务、运行时缓存以及安装目录。'
    msg '-----------------------------------------------'
    printf 'Confirm uninstall? (1/0) > '
    read -r res
    [ "$res" = 1 ]
}

remove_runtime_dirs() {
    if [ -n "$BINDIR" ]; then
        case "$BINDIR" in
            /|"$APPDIR"|"$APPDIR"/*) ;;
            *) rm -rf "$BINDIR" 2>/dev/null ;;
        esac
    fi

    [ -n "$TMPDIR" ] && [ "$TMPDIR" != / ] && rm -rf "$TMPDIR" 2>/dev/null
}

main() {
    [ -d "$APPDIR" ] || {
        msg 'Install directory not found. / 安装目录不存在。'
        exit 1
    }

    confirm_uninstall || {
        msg 'Uninstall cancelled. / 已取消卸载。'
        exit 1
    }

    "$APPDIR/start.sh" web-stop >/dev/null 2>&1 || true
    "$APPDIR/start.sh" stop >/dev/null 2>&1 || true
    "$APPDIR/start.sh" uninstall-cleanup >/dev/null 2>&1 || true

    remove_runtime_dirs

    [ "$APPDIR" != / ] && rm -rf "$APPDIR"

    msg 'ShellEasytier has been removed. / ShellEasytier 已卸载。'
    msg 'If the current shell still keeps old aliases, reopen the session.'
    msg '如果当前终端仍保留旧别名，请重新打开终端会话。'
}

main "$@"
