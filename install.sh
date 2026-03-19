#!/bin/sh
# Copyright (C) ShellEasytier
# 一键安装脚本

echo "***********************************************"
echo "**                 欢迎使用                  **"
echo "**              ShellEasytier                **"
echo "**        EasyTier 客户端 for 路由器         **"
echo "***********************************************"

# 检测架构
detect_arch() {
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)     echo "x86_64" ;;
        aarch64|arm64)    echo "aarch64" ;;
        armv7l|armv7)     echo "armv7" ;;
        mips)             echo "mips" ;;
        mipsel)           echo "mipsel" ;;
        *)                echo "generic" ;;
    esac
}

ARCH=$(detect_arch)

# 获取最新版本号
cecho() {
    printf '%b\n' "$*"
}

cecho "\033[36m正在获取最新版本信息...\033[0m"
LATEST_VERSION=$(curl -sL --connect-timeout 5 \
    "https://api.github.com/repos/AisonSu/ShellEasytier/releases/latest" 2>/dev/null | \
    grep -o '"tag_name": "[^"]*"' | head -1 | cut -d'"' -f4)

# 如果获取失败，使用默认版本
if [ -z "$LATEST_VERSION" ]; then
    cecho "\033[33m无法获取最新版本，使用默认版本\033[0m"
    LATEST_VERSION="v1.2.5"
fi

echo "**       最新版本: $LATEST_VERSION              **"
echo "**       架构: $ARCH                            **"
echo "***********************************************"

# 安装源
[ -z "$url" ] && url="https://github.com/AisonSu/ShellEasytier/releases/download/${LATEST_VERSION}"

# 内置工具
cecho() {
    printf '%b\n' "$*"
}

dir_avail() {
    df -h >/dev/null 2>&1 && h="$2"
	df -P $h "${1:-.}" 2>/dev/null | awk 'NR==2 {print $4}'
}

ckcmd() {
    if command -v sh >/dev/null 2>&1; then
        command -v "$1" >/dev/null 2>&1
    else
        type "$1" >/dev/null 2>&1
    fi
}

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

error_down() {
    cecho "\033[33m下载失败！请检查网络连接。\033[0m"
    cecho "\033[36m可手动下载并解压到目标目录。\033[0m"
}

# 检测系统类型
detect_system() {
    systype=""
    # 优先检测小米（特有的 crontab 路径）
    [ -f "/data/etc/crontabs/root" ] && systype="xiaomi"
    # 检测 OpenWrt（小米也有 /etc/rc.common，所以只在未检测到时才设置）
    [ -z "$systype" ] && [ -f "/etc/rc.common" ] && [ "$(cat /proc/1/comm)" = "procd" ] && systype="openwrt"
    # 检测 ASUS
    [ -d "/jffs" ] && systype="asus"
    # 默认
    [ -z "$systype" ] && systype="generic"
    echo "$systype"
}

# 小米路由器设置目录
set_xiaomi_dir() {
    cecho "\033[33m检测到小米路由器，请选择安装位置\033[0m"
    [ -d /data ] && cecho " 1 安装到 /data 目录,剩余空间: $(dir_avail /data -h) (推荐)"
    [ -d /userdisk ] && cecho " 2 安装到 /userdisk 目录,剩余空间: $(dir_avail /userdisk -h)"
    [ -d /data/other_vol ] && cecho " 3 安装到 /data/other_vol 目录"
    cecho " 4 安装到自定义目录"
    cecho " 0 退出安装"
    echo "-----------------------------------------------"
    read -p "请输入相应数字 > " num
    case "$num" in
    1)
        dir=/data
        ;;
    2)
        dir=/userdisk
        ;;
    3)
        dir=/data/other_vol
        ;;
    4)
        set_cust_dir
        ;;
    *)
        exit 1
        ;;
    esac
}

# 自定义目录
set_cust_dir() {
    while true; do
        echo "-----------------------------------------------"
        echo "可用路径 剩余空间:"
        df -h | awk '{print $6,$4}' | sed 1d
        echo "-----------------------------------------------"
        echo "请输入安装路径 (如 /opt/shelleasytier):"
        read -p "> " dir
        if [ -z "$dir" ]; then
            cecho "\033[31m路径不能为空！\033[0m"
            continue
        fi
        if [ ! -d "$dir" ]; then
            cecho "\033[33m目录不存在，是否创建? (y/n)\033[0m"
            read -p "> " res
            [ "$res" = "y" ] && mkdir -p "$dir"
        fi
        break
    done
}

# 安装主流程
install_main() {
    systype=$(detect_system)

    echo "-----------------------------------------------"
    cecho "\033[36m检测到系统类型: $systype\033[0m"
    echo "-----------------------------------------------"

    # 选择安装目录
    case "$systype" in
    xiaomi)
        set_xiaomi_dir
        ;;
    openwrt)
        cecho "OpenWrt 系统将安装到 /etc/shelleasytier"
        dir=/etc/shelleasytier
        ;;
    *)
        [ -z "$dir" ] && set_cust_dir
        ;;
    esac

    EASYDIR="$dir/ShellEasytier"
    echo "-----------------------------------------------"
    cecho "\033[32m安装目录: $EASYDIR\033[0m"
    echo "-----------------------------------------------"

    # 检查是否已安装
    if [ -d "$EASYDIR" ]; then
        cecho "\033[33m检测到已安装 ShellEasytier\033[0m"
        cecho "1) 覆盖安装 (保留配置)"
        cecho "2) 全新安装 (删除配置)"
        cecho "0) 取消安装"
        read -p "> " choice
        case "$choice" in
        1)
            # 备份配置
            [ -d "$EASYDIR/configs" ] && cp -r "$EASYDIR/configs" /tmp/se_configs_backup/
            rm -rf "$EASYDIR"
            ;;
        2)
            rm -rf "$EASYDIR"
            ;;
        *)
            exit 1
            ;;
        esac
    fi

    # 创建目录
    mkdir -p "$EASYDIR"

    # 下载架构特定的安装包
    cecho "\033[36m正在下载 ShellEasytier (${ARCH})...\033[0m"

    # 先尝试下载架构特定版本
    webget /tmp/ShellEasytier.tar.gz \
        "https://github.com/AisonSu/ShellEasytier/releases/download/${LATEST_VERSION}/ShellEasytier-${ARCH}.tar.gz" \
        echooff

    # 如果失败，尝试下载通用版本
    if [ "$result" != "200" ]; then
        cecho "\033[33m架构特定版本下载失败，尝试通用版本...\033[0m"
        webget /tmp/ShellEasytier.tar.gz \
            "https://github.com/AisonSu/ShellEasytier/releases/download/${LATEST_VERSION}/ShellEasytier-generic.tar.gz" \
            echooff
    fi

    if [ "$result" != "200" ]; then
        cecho "\033[31m下载失败！请检查网络或手动安装。\033[0m"
        cecho "\033[90m尝试下载: ShellEasytier-${ARCH}.tar.gz\033[0m"
        cecho "\033[90m或: ShellEasytier-generic.tar.gz\033[0m"
        cecho "\033[90m版本: $LATEST_VERSION\033[0m"
        error_down
        exit 1
    fi

    # 创建 EASYDIR 并解压
    echo "-----------------------------------------------"
    cecho "\033[36m正在解压...\033[0m"
    mkdir -p "$EASYDIR"
    if tar -zxf /tmp/ShellEasytier.tar.gz -C "$EASYDIR/" 2>/dev/null || \
       tar -zxf /tmp/ShellEasytier.tar.gz --no-same-owner -C "$EASYDIR/" 2>/dev/null; then
        cecho "\033[32m解压成功！\033[0m"

        # 检查压缩包内的版本
        package_version=$(cat "$EASYDIR/version" 2>/dev/null || echo "unknown")
        cecho "\033[36m安装包版本: $package_version\033[0m"

        # 版本对比提示
        if [ "$package_version" != "$LATEST_VERSION" ]; then
            cecho "\033[33m注意: 预期版本($LATEST_VERSION)与安装包版本($package_version)不一致\033[0m"
        else
            cecho "\033[32m✓ 版本核对通过\033[0m"
        fi
    else
        cecho "\033[31m解压失败！\033[0m"
        exit 1
    fi

    # 恢复配置
    if [ -d /tmp/se_configs_backup ]; then
        cp -r /tmp/se_configs_backup/* "$EASYDIR/configs/" 2>/dev/null
        rm -rf /tmp/se_configs_backup
    fi

    # 安装 EasyTier 二进制（预下载在包中）
    echo "-----------------------------------------------"
    cecho "\033[36m正在安装 EasyTier 核心...\033[0m"

    # 检测架构
    arch=$(uname -m)
    case "$arch" in
        x86_64)  ET_ARCH="x86_64" ;;
        aarch64|arm64) ET_ARCH="aarch64" ;;
        armv7l|armv7)  ET_ARCH="armv7" ;;
        arm*)    ET_ARCH="arm" ;;
        mips)    ET_ARCH="mips" ;;
        mipsel)  ET_ARCH="mipsel" ;;
        *)       ET_ARCH="unknown" ;;
    esac

    # 查找对应的二进制文件
    if [ "$ET_ARCH" != "unknown" ] && [ -f "$EASYDIR/bin/easytier-core-${ET_ARCH}" ]; then
        cp "$EASYDIR/bin/easytier-core-${ET_ARCH}" "$EASYDIR/bin/easytier-core"
        chmod +x "$EASYDIR/bin/easytier-core"
        cecho "\033[32mEasyTier 安装成功！ (${ET_ARCH})\033[0m"
    elif [ -f "$EASYDIR/bin/easytier-core" ]; then
        # 如果已经存在默认的 easytier-core
        cecho "\033[32mEasyTier 已存在\033[0m"
    else
        cecho "\033[33m未找到适合架构 ${arch} 的 EasyTier 二进制\033[0m"
        cecho "\033[33m请手动下载 EasyTier 到 $EASYDIR/bin/\033[0m"
        cecho "\033[36m地址: https://github.com/EasyTier/EasyTier/releases\033[0m"
    fi

    # 运行初始化
    export EASYDIR
    if [ -f "$EASYDIR/scripts/init.sh" ]; then
        cecho "\033[36m正在初始化...\033[0m"
        . "$EASYDIR/scripts/init.sh"
    else
        cecho "\033[31m初始化脚本缺失！\033[0m"
        exit 1
    fi

    # 清理
    rm -f /tmp/ShellEasytier.tar.gz

    echo "***********************************************"
    cecho "\033[32m**              安装成功！                   **\033[0m"
    echo "***********************************************"
    cecho "\033[36m使用方式:\033[0m"
    cecho "  se            - 启动菜单"
    cecho "  se -s start   - 启动服务"
    cecho "  se -s stop    - 停止服务"
    cecho "  se -s status  - 查看状态"
    echo "***********************************************"
    cecho "\033[33m请运行 'se' 或 '$EASYDIR/scripts/menu.sh' 开始配置\033[0m"
}

# 执行安装
install_main
