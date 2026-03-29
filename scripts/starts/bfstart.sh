#!/bin/sh

[ -z "$APPDIR" ] && APPDIR=$(
    cd "$(dirname "$0")/../.."
    pwd
)
export APPDIR

. "$APPDIR/scripts/libs/get_config.sh"
. "$APPDIR/scripts/libs/logger.sh"
. "$APPDIR/scripts/libs/check_arch.sh"
. "$APPDIR/scripts/libs/prepare_runtime.sh"
. "$APPDIR/scripts/libs/render_local_toml.sh"
. "$APPDIR/scripts/libs/build_command.sh"

[ -f "$APPDIR/.start_error" ] && exit 1

[ -w "$APPDIR/configs" ] || {
    logger '当前安装目录需要写权限，请使用 root 或 sudo 运行 ShellEasytier。' 31
    exit 1
}

check_et_arch || {
    logger '不支持当前设备架构，无法启动 EasyTier。' 31
    exit 1
}

if [ "$et_mode" = remote ]; then
    config_server_value=$(resolve_config_server_value)
    [ -n "$config_server_value" ] || {
        logger '远程模式需要先配置 config-server。' 31
        exit 1
    }
fi

sync_runtime_binaries || {
    logger '运行时二进制准备失败，请检查安装目录空间或 pkg 内容。' 31
    exit 1
}

logger "运行时目录: $BINDIR" 32 off

mkdir -p "$TMPDIR" 2>/dev/null
[ -n "$file_log_dir" ] && mkdir -p "$file_log_dir" 2>/dev/null

if [ "$et_mode" = local ]; then
    render_local_toml || {
        logger '本地模式配置文件生成失败。' 31
        exit 1
    }
fi

refresh_command_env || {
    logger '启动命令生成失败。' 31
    exit 1
}

exit 0
