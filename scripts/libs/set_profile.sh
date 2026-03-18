#!/bin/sh
# Copyright (C) ShellEasytier
# Shell 配置文件设置

# 设置环境变量
set_profile() {
    profile_file="$1"
    [ -z "$profile_file" ] && return 1

    # 检查是否已设置
    if grep -q "ShellEasytier" "$profile_file" 2>/dev/null; then
        return 0
    fi

    cat >> "$profile_file" << EOF

# ShellEasytier Environment
export EASYDIR="${EASYDIR:-/data/ShellEasytier}"
export PATH="\$PATH:\$EASYDIR/bin"
alias se='"\$EASYDIR"/scripts/menu.sh'
alias easytier='"\$EASYDIR"/scripts/menu.sh'
EOF
}

# 移除配置
unset_profile() {
    profile_file="$1"
    [ -z "$profile_file" ] && return 1
    [ -f "$profile_file" ] || return 0

    sed -i '/ShellEasytier/d' "$profile_file"
    sed -i '/EASYDIR/d' "$profile_file"
    sed -i '/alias se/d' "$profile_file"
    sed -i '/alias easytier/d' "$profile_file"
}
