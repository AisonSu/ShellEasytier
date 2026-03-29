#!/bin/sh

[ -z "$APPDIR" ] && APPDIR=$(
    cd "$(dirname "$0")"
    pwd
)
export APPDIR

. "$APPDIR/scripts/init.sh"
