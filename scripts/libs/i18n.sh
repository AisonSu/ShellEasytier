#!/bin/sh
# Copyright (C) ShellEasytier
# 国际化支持库

load_lang() {
    i18n=$(cat "$EASYDIR"/configs/i18n.cfg 2>/dev/null)
	[ -z "$i18n" ] && i18n=chs

    file="$EASYDIR/scripts/lang/$i18n/$1.lang"
    [ -s "$file" ] && . "$file"
}
