#!/bin/sh

[ -z "$APPDIR" ] && APPDIR=$(
    cd "$(dirname "$0")/../.."
    pwd
)
export APPDIR

. "$APPDIR/scripts/libs/get_config.sh"
. "$APPDIR/scripts/libs/logger.sh"
. "$APPDIR/scripts/libs/start_wait.sh"

if start_wait; then
    logger 'ShellEasytier 服务已启动。' 32
    exit 0
fi

logger 'ShellEasytier 服务启动超时。' 31
"$APPDIR/scripts/starts/start_error.sh"
exit 1
