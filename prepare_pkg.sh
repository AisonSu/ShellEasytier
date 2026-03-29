#!/usr/bin/env bash

set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PKG_DIR="$REPO_ROOT/pkg"
TMP_DIR=$(mktemp -d)

ARCHES="x86_64 aarch64 arm armhf armv7 armv7hf mips mipsel"
PARALLEL_JOBS="${PARALLEL_JOBS:-4}"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT INT TERM

log() {
    printf '%s\n' "$*"
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

fetch_latest_version() {
    if have_cmd curl; then
        curl -fsSL "https://api.github.com/repos/EasyTier/EasyTier/releases/latest" |
            sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
            head -n 1
    elif have_cmd wget; then
        wget -qO- "https://api.github.com/repos/EasyTier/EasyTier/releases/latest" |
            sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
            head -n 1
    else
        die "curl or wget is required"
    fi
}

normalize_version() {
    case "$1" in
        v*) printf '%s\n' "$1" ;;
        *) printf 'v%s\n' "$1" ;;
    esac
}

download_file() {
    url="$1"
    output="$2"

    if have_cmd curl; then
        curl -fL "$url" -o "$output"
    elif have_cmd wget; then
        wget -O "$output" "$url"
    else
        die "curl or wget is required"
    fi
}

extract_archive() {
    archive="$1"
    target_dir="$2"

    mkdir -p "$target_dir"

    case "$archive" in
        *.zip)
            if have_cmd unzip; then
                unzip -qo "$archive" -d "$target_dir"
            elif have_cmd bsdtar; then
                bsdtar -xf "$archive" -C "$target_dir"
            else
                die "zip extraction requires unzip or bsdtar"
            fi
            ;;
        *.tar.gz|*.tgz)
            if have_cmd tar; then
                tar -xzf "$archive" -C "$target_dir"
            elif have_cmd bsdtar; then
                bsdtar -xf "$archive" -C "$target_dir"
            else
                die "tar extraction requires tar or bsdtar"
            fi
            ;;
        *)
            die "unsupported archive format: $archive"
            ;;
    esac
}

find_payload_dir() {
    root="$1"
    arch="$2"

    if [ -d "$root/easytier-linux-$arch" ]; then
        printf '%s\n' "$root/easytier-linux-$arch"
        return 0
    fi

    found=$(find "$root" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    [ -n "$found" ] || return 1
    printf '%s\n' "$found"
}

write_pkg_info() {
    arch="$1"
    pkg_path="$2"
    version="$3"

    {
        printf 'version=%s\n' "$version"
        printf 'arch=%s\n' "$arch"
        [ -f "$pkg_path/easytier-core" ] && printf 'has_core=1\n' || printf 'has_core=0\n'
        [ -f "$pkg_path/easytier-cli" ] && printf 'has_cli=1\n' || printf 'has_cli=0\n'
        [ -f "$pkg_path/easytier-web-embed" ] && printf 'has_web_embed=1\n' || printf 'has_web_embed=0\n'
    } > "$pkg_path/pkg.info"
}

prepare_arch_pkg() {
    arch="$1"
    version="$2"
    base_url="https://github.com/EasyTier/EasyTier/releases/download/$version"

    archive_name="easytier-linux-$arch-$version.zip"
    archive_path="$TMP_DIR/$archive_name"

    log "==> preparing $arch"

    if ! download_file "$base_url/$archive_name" "$archive_path"; then
        archive_name="easytier-linux-$arch-$version.tar.gz"
        archive_path="$TMP_DIR/$archive_name"
        download_file "$base_url/$archive_name" "$archive_path"
    fi

    extract_root="$TMP_DIR/extract-$arch"
    rm -rf "$extract_root"
    extract_archive "$archive_path" "$extract_root"

    payload_dir=$(find_payload_dir "$extract_root" "$arch") || die "cannot find payload dir for $arch"

    target_dir="$PKG_DIR/$arch"
    rm -rf "$target_dir"
    mkdir -p "$target_dir"

    for bin_name in easytier-core easytier-cli easytier-web-embed; do
        if [ -f "$payload_dir/$bin_name" ]; then
            cp "$payload_dir/$bin_name" "$target_dir/$bin_name"
            chmod 755 "$target_dir/$bin_name"
        fi
    done

    write_pkg_info "$arch" "$target_dir" "$version"
}

wait_for_slot() {
    while :; do
        running=$(jobs -pr | wc -l | awk '{print $1}')
        [ "$running" -lt "$PARALLEL_JOBS" ] && return 0
        sleep 1
    done
}

prepare_all_arches() {
    version="$1"
    pid_list=""
    failed=0

    for arch in $ARCHES; do
        wait_for_slot
        prepare_arch_pkg "$arch" "$version" &
        pid_list="$pid_list $!:$arch"
    done

    for item in $pid_list; do
        pid=${item%%:*}
        arch=${item#*:}
        if ! wait "$pid"; then
            printf 'ERROR: failed to prepare %s\n' "$arch" >&2
            failed=1
        fi
    done

    [ "$failed" -eq 0 ] || die "one or more architecture packages failed"
}

write_manifest() {
    version="$1"
    manifest="$PKG_DIR/manifest.txt"

    : > "$manifest"
    printf 'version=%s\n' "$version" >> "$manifest"
    for arch in $ARCHES; do
        if [ -f "$PKG_DIR/$arch/pkg.info" ]; then
            printf '\n[%s]\n' "$arch" >> "$manifest"
            cat "$PKG_DIR/$arch/pkg.info" >> "$manifest"
        fi
    done
}

main() {
    input_version="${1:-latest}"
    if [ "$input_version" = "latest" ]; then
        input_version=$(fetch_latest_version)
    fi

    version=$(normalize_version "$input_version")
    [ -n "$version" ] || die "failed to resolve release version"

    mkdir -p "$PKG_DIR"
    prepare_all_arches "$version"

    write_manifest "$version"

    log "==> done"
    log "packages: $PKG_DIR"
}

main "$@"
