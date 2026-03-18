#!/bin/sh
# Copyright (C) ShellEasytier
# 构建发布包脚本

VERSION=$(cat version)
BUILD_DIR="/tmp/selleasytier_build"

cecho() {
    printf '%b\n' "$*"
}

cecho "\033[36mBuilding ShellEasytier v$VERSION...\033[0m"

# 清理并创建构建目录
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 复制文件
cp -r scripts "$BUILD_DIR/"
cp -r starts "$BUILD_DIR/"
cp -r bin "$BUILD_DIR/" 2>/dev/null || mkdir -p "$BUILD_DIR/bin"
cp version "$BUILD_DIR/"
cp README.md "$BUILD_DIR/" 2>/dev/null

# 设置权限
chmod +x "$BUILD_DIR/scripts/"*.sh
chmod +x "$BUILD_DIR/scripts/libs/"*.sh
chmod +x "$BUILD_DIR/scripts/menus/"*.sh
chmod +x "$BUILD_DIR/scripts/check_and_start.sh"

# 创建压缩包
tar -czf "ShellEasytier.tar.gz" -C "$BUILD_DIR" .

# 清理
rm -rf "$BUILD_DIR"

cecho "\033[32mBuild complete: ShellEasytier.tar.gz\033[0m"
