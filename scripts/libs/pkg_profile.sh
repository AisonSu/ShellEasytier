[ -n "$__IS_LIB_PKG_PROFILE" ] && return
__IS_LIB_PKG_PROFILE=1

[ -n "$APPDIR" ] && . "$APPDIR/scripts/libs/check_arch.sh"

ET_CORE_MIN_KB=12288
ET_WEB_MIN_KB=32768
ET_FULL_MIN_KB=49152

arch_supports_web_embed() {
    case "$1" in
        x86_64|aarch64|arm|armhf|armv7|armv7hf)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

get_path_free_kb() {
    df -Pk "$1" 2>/dev/null | awk 'NR==2 {print $4}'
}

detect_pkg_support() {
    [ -n "$et_arch" ] || check_et_arch || return 1

    ET_PKGDIR="$APPDIR/pkg/$et_arch"
    ET_HAS_CORE=0
    ET_HAS_CLI=0
    ET_HAS_WEB_EMBED=0

    [ -n "$update_url" ] && ET_BIN_BASE_URL="$update_url/pkg/$et_arch" || ET_BIN_BASE_URL=""

    [ -n "$ET_BIN_BASE_URL" ] && ET_HAS_CORE=1
    [ -n "$ET_BIN_BASE_URL" ] && ET_HAS_CLI=1
    arch_supports_web_embed "$et_arch" && ET_HAS_WEB_EMBED=1

    export ET_PKGDIR ET_HAS_CORE ET_HAS_CLI ET_HAS_WEB_EMBED ET_BIN_BASE_URL
    [ "$ET_HAS_CORE" = 1 ] && [ "$ET_HAS_CLI" = 1 ]
}

choose_runtime_layout() {
    detect_pkg_support || return 1

    tmp_base="${TMPDIR:-/tmp/ShellEasytier}"
    crash_free=$(get_path_free_kb "$APPDIR")
    tmp_free=$(get_path_free_kb "${TMPDIR:-/tmp}")

    ET_LAYOUT=""
    ET_BINDIR=""
    ET_ALLOW_WEB=0

    if [ "$ET_HAS_WEB_EMBED" = 1 ]; then
        if [ -n "$crash_free" ] && [ "$crash_free" -ge "$ET_FULL_MIN_KB" ]; then
            ET_LAYOUT="persistent-full"
            ET_BINDIR="$APPDIR/bin/$et_arch"
            ET_ALLOW_WEB=1
        elif [ -n "$tmp_free" ] && [ "$tmp_free" -ge "$ET_WEB_MIN_KB" ]; then
            ET_LAYOUT="tmp-full"
            ET_BINDIR="$tmp_base/bin/$et_arch"
            ET_ALLOW_WEB=1
        fi
    fi

    if [ -z "$ET_LAYOUT" ]; then
        if [ -n "$crash_free" ] && [ "$crash_free" -ge "$ET_CORE_MIN_KB" ]; then
            ET_LAYOUT="persistent-core"
            ET_BINDIR="$APPDIR/bin/$et_arch"
        elif [ -n "$tmp_free" ] && [ "$tmp_free" -ge "$ET_CORE_MIN_KB" ]; then
            ET_LAYOUT="tmp-core"
            ET_BINDIR="$tmp_base/bin/$et_arch"
        else
            return 1
        fi
    fi

    export ET_LAYOUT ET_BINDIR ET_ALLOW_WEB
    return 0
}

can_offer_local_web_menu() {
    [ "$install_web" = ON ] || return 1

    choose_runtime_layout || return 1

    [ "$ET_ALLOW_WEB" = 1 ] || return 1

    [ "$ET_HAS_WEB_EMBED" = 1 ]
}
