#!/bin/sh
# Copyright (C) ShellEasytier
# 日志工具库

# 日志文件路径
LOG_FILE="${EASY_TMPDIR:-/tmp/ShellEasytier}/easytier.log"

# 初始化日志
init_log() {
    [ ! -d "$(dirname "$LOG_FILE")" ] && mkdir -p "$(dirname "$LOG_FILE")"
    echo "# ShellEasytier Log - $(date)" > "$LOG_FILE"
}

# 记录日志
# 参数1: 日志级别 (INFO/WARN/ERROR/DEBUG)
# 参数2: 日志内容
log() {
    level="$1"
    message="$2"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_info() {
    log "INFO" "$1"
}

log_warn() {
    log "WARN" "$1"
}

log_error() {
    log "ERROR" "$1"
}

log_debug() {
    [ "$DEBUG" = "1" ] && log "DEBUG" "$1"
}

# 获取日志内容
get_log() {
    [ -f "$LOG_FILE" ] && cat "$LOG_FILE"
}

# 清空日志
clear_log() {
    > "$LOG_FILE"
}

# 查看最后N行日志
# 参数1: 行数 (默认50)
tail_log() {
    lines="${1:-50}"
    [ -f "$LOG_FILE" ] && tail -n "$lines" "$LOG_FILE"
}
