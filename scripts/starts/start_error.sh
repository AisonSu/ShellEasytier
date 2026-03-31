#!/bin/sh

[ -z "$APPDIR" ] && APPDIR=$(
    cd "$(dirname "$0")/../.."
    pwd
)
export APPDIR

. "$APPDIR/scripts/libs/get_config.sh"
. "$APPDIR/scripts/libs/check_autostart.sh"
. "$APPDIR/scripts/libs/logger.sh"

touch "$APPDIR/.start_error"
disable_core_autostart >/dev/null 2>&1
logger 'ShellEasytier 启动失败，已写入熔断标记。' 31
"$APPDIR/start.sh" stop >/dev/null 2>&1
