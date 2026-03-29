[ -n "$__IS_LIB_PREPARE_RUNTIME" ] && return
__IS_LIB_PREPARE_RUNTIME=1

. "$APPDIR/scripts/libs/pkg_profile.sh"

download_runtime_file() {
    url="$1"
    output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -kfsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate -qO "$output" "$url"
    else
        return 1
    fi
}

runtime_binaries_ready() {
    [ -s "$ET_BINDIR/easytier-core" ] || return 1
    [ -s "$ET_BINDIR/easytier-cli" ] || return 1

    if [ "$install_web" = ON ] && [ "$ET_ALLOW_WEB" = 1 ] && [ "$ET_HAS_WEB_EMBED" = 1 ]; then
        [ -s "$ET_BINDIR/easytier-web-embed" ] || return 1
    fi

    return 0
}

runtime_cache_valid() {
    [ -f "$ET_BINDIR/.release_version" ] || return 1
    [ -f "$ET_BINDIR/.release_arch" ] || return 1
    runtime_binaries_ready || return 1
    [ "$(cat "$ET_BINDIR/.release_version" 2>/dev/null)" = "$release_version" ] || return 1
    [ "$(cat "$ET_BINDIR/.release_arch" 2>/dev/null)" = "$et_arch" ] || return 1

    return 0
}

write_runtime_meta() {
    printf '%s\n' "$release_version" > "$ET_BINDIR/.release_version"
    printf '%s\n' "$et_arch" > "$ET_BINDIR/.release_arch"
}

sync_runtime_binaries() {
    choose_runtime_layout || return 1

    mkdir -p "$ET_BINDIR" "$TMPDIR" 2>/dev/null || return 1

    runtime_cache_valid && {
        BINDIR="$ET_BINDIR"
        export BINDIR TMPDIR
        return 0
    }

    tmp_dl="$TMPDIR/download.$$"
    rm -rf "$tmp_dl"
    mkdir -p "$tmp_dl" || return 1

    for file in easytier-core easytier-cli; do
        download_runtime_file "$ET_BIN_BASE_URL/$file" "$tmp_dl/$file" || {
            rm -rf "$tmp_dl"
            return 1
        }
        [ -s "$tmp_dl/$file" ] || {
            rm -rf "$tmp_dl"
            return 1
        }
        chmod 755 "$tmp_dl/$file"
    done

    for file in easytier-core easytier-cli; do
        cp -f "$tmp_dl/$file" "$ET_BINDIR/$file"
        chmod 755 "$ET_BINDIR/$file"
    done

    if [ "$install_web" = ON ] && [ "$ET_ALLOW_WEB" = 1 ] && [ "$ET_HAS_WEB_EMBED" = 1 ]; then
        download_runtime_file "$ET_BIN_BASE_URL/easytier-web-embed" "$tmp_dl/easytier-web-embed" || {
            rm -rf "$tmp_dl"
            return 1
        }
        [ -s "$tmp_dl/easytier-web-embed" ] || {
            rm -rf "$tmp_dl"
            return 1
        }
        chmod 755 "$tmp_dl/easytier-web-embed"
        cp -f "$tmp_dl/easytier-web-embed" "$ET_BINDIR/easytier-web-embed"
        chmod 755 "$ET_BINDIR/easytier-web-embed"
    else
        rm -f "$ET_BINDIR/easytier-web-embed"
    fi

    runtime_binaries_ready || {
        rm -rf "$tmp_dl"
        return 1
    }

    write_runtime_meta
    rm -rf "$tmp_dl"

    BINDIR="$ET_BINDIR"
    export BINDIR TMPDIR
    return 0
}
