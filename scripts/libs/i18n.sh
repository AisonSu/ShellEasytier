[ -n "$__IS_LIB_I18N" ] && return
__IS_LIB_I18N=1

load_lang() {
    i18n=$(cat "$APPDIR/configs/i18n.cfg" 2>/dev/null)
    [ -z "$i18n" ] && i18n=chs

    file="$APPDIR/scripts/lang/$i18n/$1.lang"
    [ -s "$file" ] && . "$file"
}
