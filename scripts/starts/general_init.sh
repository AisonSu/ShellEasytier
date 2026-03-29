#!/bin/sh

[ -z "$APPDIR" ] && APPDIR=$(
    cd "$(dirname "$0")/../.."
    pwd
)
export APPDIR

if [ ! -f "$APPDIR/.start_error" ] && [ ! -f "$APPDIR/.dis_startup_core" ]; then
    "$APPDIR/start.sh" start
fi

if [ ! -f "$APPDIR/.dis_startup_web" ]; then
    "$APPDIR/start.sh" web-start
fi
