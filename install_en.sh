#!/bin/sh

[ -z "$url" ] && url='https://github.com/AisonSu/ShellEasyTier/releases/latest/download'
export url
export language=en

if command -v curl >/dev/null 2>&1; then
    sh -c "$(curl -kfsSl "$url/install.sh")"
elif command -v wget >/dev/null 2>&1; then
    sh -c "$(wget --no-check-certificate -qO- "$url/install.sh")"
else
    echo 'curl or wget is required.' >&2
    exit 1
fi
