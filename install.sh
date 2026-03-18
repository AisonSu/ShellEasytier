#!/bin/sh
# Copyright (C) ShellEasytier
# 一键安装脚本

echo "***********************************************"
echo "**                 欢迎使用                  **"
echo "**              ShellEasytier                **"
echo "**        EasyTier 客户端 for 路由器         **"
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
    [ -f "/data/etc/crontabs/root" ] && systype="xiaomi"
    [ -f "/etc/rc.common" ] && [ "$(cat /proc/1/comm)" = "procd" ] && systype="openwrt"
    [ -d "/jffs" ] && systype="asus"
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

    # 下载安装包 - 尝试多个镜像源
    cecho "\033[36m正在下载 ShellEasytier...\033[0m"

    # 备用下载源列表
    mirrors="
        https://ghproxy.com/https://github.com/AisonSu/ShellEasytier/releases/latest/download/ShellEasytier.tar.gz
        https://mirror.ghproxy.com/https://github.com/AisonSu/ShellEasytier/releases/latest/download/ShellEasytier.tar.gz
        https://github.com/AisonSu/ShellEasytier/releases/latest/download/ShellEasytier.tar.gz
    "

    for mirror in $mirrors; do
        cecho "\033[33m尝试下载源: $(echo $mirror | cut -d'/' -f3)\033[0m"
        webget /tmp/ShellEasytier.tar.gz "$mirror" echooff 2>/dev/null
        [ "$result" = "200" ] && break
    done

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
    else
        cecho "\033[31m解压失败！\033[0m"
        exit 1
    fi

    # 恢复配置
    if [ -d /tmp/se_configs_backup ]; then
        cp -r /tmp/se_configs_backup/* "$EASYDIR/configs/" 2>/dev/null
        rm -rf /tmp/se_configs_backup
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
