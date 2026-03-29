#!/usr/bin/env bash

set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
OUT_FILE="$REPO_ROOT/ShellEasytier.tar.gz"
TMP_FILE="${TMPDIR:-/tmp}/ShellEasytier.$$.tar.gz"

rm -f "$OUT_FILE"
rm -f "$TMP_FILE"

tar -czf "$TMP_FILE" \
    --exclude='ShellEasytier.tar.gz' \
    --exclude='ShellEasytier/pkg' \
    --exclude='ShellEasytier/public' \
    --exclude='ShellEasytier/bin' \
    --exclude='.git' \
    -C "$(dirname "$REPO_ROOT")" \
    "$(basename "$REPO_ROOT")"

mv -f "$TMP_FILE" "$OUT_FILE"

printf 'created %s\n' "$OUT_FILE"
