#!/bin/sh

[ -z "$APPDIR" ] && APPDIR=$(
    cd "$(dirname "$0")"
    pwd
)
export APPDIR

exec /bin/sh "$APPDIR/scripts/uninstall.sh" "$@"
