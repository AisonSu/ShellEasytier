#!/bin/sh
# Copyright (C) ShellEasytier
# 网络下载工具库

# 下载文件
# 参数1: 保存路径
# 参数2: 下载URL
# 参数3: 输出模式 (echooff/on)
# 参数4: 是否禁用重定向 (rediroff)
webget() {
    if curl --version >/dev/null 2>&1; then
        [ "$3" = "echooff" ] && progress='-s' || progress='-#'
        [ -z "$4" ] && redirect='-L' || redirect=''
        result=$(curl -w %{http_code} --connect-timeout 5 "$progress" "$redirect" -ko "$1" "$2")
        [ -n "$(echo $result | grep -e ^2)" ] && result="200"
    else
        if wget --version >/dev/null 2>&1; then
            [ "$3" = "echooff" ] && progress='-q' || progress='-q --show-progress'
            [ "$4" = "rediroff" ] && redirect='--max-redirect=0' || redirect=''
            certificate='--no-check-certificate'
            timeout='--timeout=3'
        fi
        [ "$3" = "echoon" ] && progress=''
        [ "$3" = "echooff" ] && progress='-q'
        wget "$progress" "$redirect" "$certificate" "$timeout" -O "$1" "$2"
        [ $? -eq 0 ] && result="200"
    fi
}

# 下载并解压 easytier 二进制文件
# 参数1: 目标架构
download_easytier() {
    arch="$1"
    [ -z "$arch" ] && arch=$(uname -m)

    # 架构映射
    case "$arch" in
        x86_64|amd64)
            ET_ARCH="x86_64-unknown-linux-musl"
            ;;
        aarch64|arm64)
            ET_ARCH="aarch64-unknown-linux-musl"
            ;;
        armv7l|armhf)
            ET_ARCH="armv7-unknown-linux-musleabihf"
            ;;
        mips)
            ET_ARCH="mips-unknown-linux-musl"
            ;;
        mipsel)
            ET_ARCH="mipsel-unknown-linux-musl"
            ;;
        *)
            return 1
            ;;
    esac

    # 下载地址
    ET_URL="https://github.com/EasyTier/EasyTier/releases/latest/download/easytier-linux-${ET_ARCH}.zip"

    # 下载到临时目录
    tmp_file="/tmp/easytier-linux-${ET_ARCH}.zip"

    webget "$tmp_file" "$ET_URL" echooff

    if [ "$result" != "200" ]; then
        return 1
    fi

    # 解压
    if unzip -o "$tmp_file" -d /tmp/easytier_extract/ 2>/dev/null; then
        # 查找 easytier-core
        core_file=$(find /tmp/easytier_extract/ -name "easytier-core" -type f | head -1)
        if [ -n "$core_file" ]; then
            mv -f "$core_file" "$EASYDIR/bin/easytier-core"
            chmod +x "$EASYDIR/bin/easytier-core"
            rm -rf /tmp/easytier_extract/ "$tmp_file"
            return 0
        fi
    fi

    rm -rf /tmp/easytier_extract/ "$tmp_file"
    return 1
}

# 检查命令是否存在
check_cmd() {
    if command -v sh >/dev/null 2>&1; then
        command -v "$1" >/dev/null 2>&1
    else
        type "$1" >/dev/null 2>&1
    fi
}
