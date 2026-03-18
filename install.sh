#!/bin/sh
# Copyright (C) ShellEasytier
# 一键安装脚本

# 安装脚本版本
INSTALL_SCRIPT_VERSION="1.0.9"

echo "***********************************************"
echo "**                 欢迎使用                  **"
echo "**              ShellEasytier                **"
echo "**        EasyTier 客户端 for 路由器         **"
echo "***********************************************"
echo "**       安装脚本版本: $INSTALL_SCRIPT_VERSION        **"
echo "***********************************************"

# 安装源
[ -z "$url" ] && url="https://github.com/AisonSu/ShellEasytier/raw/main"

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

    # 下载安装包
    cecho "\033[36m正在下载 ShellEasytier...\033[0m"
    webget /tmp/ShellEasytier.tar.gz "https://github.com/AisonSu/ShellEasytier/releases/latest/download/ShellEasytier.tar.gz" echooff

    if [ "$result" != "200" ]; then
        cecho "\033[31m下载失败！请检查网络或手动安装。\033[0m"
        error_down
        exit 1
    fi

    # 解压
    echo "-----------------------------------------------"
    cecho "\033[36m正在解压...\033[0m"
    if tar -zxf /tmp/ShellEasytier.tar.gz -C "$dir/" 2>/dev/null || \
       tar -zxf /tmp/ShellEasytier.tar.gz --no-same-owner -C "$dir/" 2>/dev/null; then
        cecho "\033[32m解压成功！\033[0m"

        # 检查压缩包内的版本
        package_version=$(cat "$EASYDIR/version" 2>/dev/null || echo "unknown")
        cecho "\033[36m安装包版本: $package_version\033[0m"

        # 版本对比提示
        if [ "$package_version" != "$INSTALL_SCRIPT_VERSION" ]; then
            cecho "\033[33m注意: 安装脚本版本($INSTALL_SCRIPT_VERSION)与安装包版本($package_version)不一致\033[0m"
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

    # 下载 EasyTier 二进制
    echo "-----------------------------------------------"
    cecho "\033[36m正在下载 EasyTier 核心...\033[0m"

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

    # 获取最新版本号
    cecho "\033[36m正在获取 EasyTier 最新版本...\033[0m"
    et_version=$(curl -sL --connect-timeout 5 "https://api.github.com/repos/EasyTier/EasyTier/releases/latest" 2>/dev/null | grep -o '"tag_name": "[^"]*"' | head -1 | cut -d'"' -f4)
    [ -z "$et_version" ] && et_version="v2.4.5"
    cecho "\033[36m最新版本: $et_version\033[0m"

    # 下载 EasyTier - 尝试多个镜像
    cecho "\033[36m正在下载 EasyTier...\033[0m"

    et_mirrors="
        https://ghproxy.com/https://github.com/EasyTier/EasyTier/releases/download/${et_version}/easytier-linux-${ET_ARCH}-${et_version}.zip
        https://mirror.ghproxy.com/https://github.com/EasyTier/EasyTier/releases/download/${et_version}/easytier-linux-${ET_ARCH}-${et_version}.zip
        https://github.com/EasyTier/EasyTier/releases/download/${et_version}/easytier-linux-${ET_ARCH}-${et_version}.zip
    "

    et_downloaded=0
    for mirror in $et_mirrors; do
        cecho "\033[33m尝试下载源: $(echo $mirror | cut -d'/' -f3)\033[0m"
        webget /tmp/easytier.zip "$mirror" echooff 2>/dev/null
        if [ "$result" = "200" ]; then
            et_downloaded=1
            break
        fi
    done

    if [ "$et_downloaded" = "1" ]; then
        cecho "\033[32m下载成功！\033[0m"
        # 解压 EasyTier
        if command -v unzip >/dev/null 2>&1; then
            unzip -o /tmp/easytier.zip -d "$EASYDIR/bin/" 2>/dev/null
            chmod +x "$EASYDIR/bin/"* 2>/dev/null
            cecho "\033[32mEasyTier 下载成功！\033[0m"
        else
            # 尝试使用 busybox unzip
            if busybox unzip -o /tmp/easytier.zip -d "$EASYDIR/bin/" 2>/dev/null; then
                chmod +x "$EASYDIR/bin/"* 2>/dev/null
                cecho "\033[32mEasyTier 下载成功！\033[0m"
            else
                cecho "\033[33m未找到 unzip，请手动解压 /tmp/easytier.zip 到 $EASYDIR/bin/\033[0m"
                cecho "\033[36m命令: mkdir -p $EASYDIR/bin \u0026\u0026 unzip /tmp/easytier.zip -d $EASYDIR/bin/\033[0m"
            fi
        fi
        rm -f /tmp/easytier.zip
    else
        cecho "\033[33mEasyTier 下载失败，请手动下载安装到 $EASYDIR/bin/\033[0m"
        cecho "\033[36m下载地址: https://github.com/EasyTier/EasyTier/releases\033[0m"
        if [ "$ET_ARCH" = "unknown" ]; then
            cecho "\033[36m检测到架构: ${arch} (未知架构，请手动选择)\033[0m"
        else
            cecho "\033[36m架构: easytier-linux-${ET_ARCH}-${et_version}.zip\033[0m"
        fi
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
