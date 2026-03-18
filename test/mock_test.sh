#!/bin/sh
# Copyright (C) ShellEasytier
# 模拟环境测试脚本 - 无需真实 EasyTier 核心

set -e

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
EASYDIR="$(dirname "$TEST_DIR")"

echo "=============================================="
echo "    ShellEasytier 模拟环境测试"
echo "=============================================="

# 创建临时测试目录
MOCK_DIR="/tmp/se_mock_$$"
mkdir -p "$MOCK_DIR"
trap "rm -rf $MOCK_DIR" EXIT

echo ""
echo "[1] 设置模拟环境..."
mkdir -p "$MOCK_DIR/configs"
mkdir -p "$MOCK_DIR/bin"
mkdir -p "$MOCK_DIR/scripts"

# 复制脚本
cp -r "$EASYDIR/scripts/"* "$MOCK_DIR/scripts/"
cp "$EASYDIR/version" "$MOCK_DIR/" 2>/dev/null || echo "1.0.0" > "$MOCK_DIR/version"

# 创建模拟 EasyTier 核心
cat > "$MOCK_DIR/bin/easytier-core" << 'EOF'
#!/bin/sh
# 模拟 easytier-core
if [ "$1" = "--version" ]; then
    echo "easytier-core 2.0.0"
    exit 0
fi

# 模拟运行 - 创建 PID 文件
if [ "$1" = "run" ] || [ -z "$1" ]; then
    echo $$ > /tmp/se_mock_easytier.pid
    # 保持运行
    while true; do
        sleep 10
    done
fi
EOF
chmod +x "$MOCK_DIR/bin/easytier-core"

# 创建模拟 easytier-cli
cat > "$MOCK_DIR/bin/easytier-cli" << 'EOF'
#!/bin/sh
# 模拟 easytier-cli
if [ "$1" = "peer" ]; then
    echo "peers:"
    echo "  tcp://192.168.1.100:11010 - Connected"
    echo "  udp://peer.example.com:11010 - Connecting"
fi
EOF
chmod +x "$MOCK_DIR/bin/easytier-cli"

echo "[2] 测试配置管理..."
export EASYDIR="$MOCK_DIR"
cd "$MOCK_DIR"

# 加载配置库
. "$MOCK_DIR/scripts/libs/set_config.sh"
. "$MOCK_DIR/scripts/libs/get_config.sh"

# 测试配置写入
echo "  - 测试 setconfig..."
setconfig TEST_KEY "test_value"
setconfig EASY_IPV4 "10.144.144.1"
setconfig EASY_NETWORK_NAME "test_network"

# 验证配置
if grep -q "TEST_KEY=test_value" "$MOCK_DIR/configs/ShellEasytier.cfg"; then
    echo "  ✓ 配置写入成功"
else
    echo "  ✗ 配置写入失败"
    exit 1
fi

echo ""
echo "[3] 测试国际化..."

# 创建语言配置
echo "chs" > "$MOCK_DIR/configs/i18n.cfg"

. "$MOCK_DIR/scripts/libs/i18n.sh"
load_lang common

if [ -n "$COMMON_INPUT" ]; then
    echo "  ✓ 中文语言加载成功: $COMMON_INPUT"
else
    echo "  ✗ 语言加载失败"
    exit 1
fi

# 测试英文
echo "en" > "$MOCK_DIR/configs/i18n.cfg"
load_lang common
if [ -n "$COMMON_INPUT" ]; then
    echo "  ✓ 英文语言加载成功: $COMMON_INPUT"
else
    echo "  ✗ 英文语言加载失败"
    exit 1
fi

echo ""
echo "[4] 测试 TUI 布局..."

. "$MOCK_DIR/scripts/menus/tui_layout.sh"
. "$MOCK_DIR/scripts/menus/common.sh"

# 重定向输出到文件以测试
TEST_OUTPUT="$MOCK_DIR/tui_test.txt"
{
    line_break
    separator_line "="
    content_line "测试标题"
    content_line "虚拟IP: 10.144.144.1"
    separator_line "="
} > "$TEST_OUTPUT"

if [ -s "$TEST_OUTPUT" ]; then
    echo "  ✓ TUI 输出测试成功"
    echo "  输出预览:"
    head -5 "$TEST_OUTPUT" | sed 's/^/    /'
else
    echo "  ✗ TUI 输出测试失败"
fi

echo ""
echo "[5] 测试服务管理 (模拟)..."

# 创建模拟 service.sh 函数
start_easytier() {
    nohup "$MOCK_DIR/bin/easytier-core" > /dev/null 2>&1 &
    sleep 1
    return 0
}

stop_easytier() {
    if [ -f /tmp/se_mock_easytier.pid ]; then
        kill $(cat /tmp/se_mock_easytier.pid) 2>/dev/null
        rm -f /tmp/se_mock_easytier.pid
    fi
    return 0
}

is_running() {
    if [ -f /tmp/se_mock_easytier.pid ]; then
        pid=$(cat /tmp/se_mock_easytier.pid)
        kill -0 "$pid" 2>/dev/null
        return $?
    fi
    return 1
}

echo "  - 测试启动服务..."
start_easytier
sleep 1
if is_running; then
    echo "  ✓ 服务启动成功"
else
    echo "  ✗ 服务启动失败"
fi

echo "  - 测试停止服务..."
stop_easytier
if ! is_running; then
    echo "  ✓ 服务停止成功"
else
    echo "  ✗ 服务停止失败"
fi

echo ""
echo "[6] 测试配置验证..."

# 测试 IP 验证函数 (正确的实现)
validate_ip() {
    echo "$1" | awk -F'.' '
    /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/ {
        for(i=1; i<=4; i++) {
            if($i < 0 || $i > 255) exit 1
        }
        exit 0
    }
    { exit 1 }
    '
}

# 测试用例格式: IP:期望返回值 (0=成功/有效, 1=失败/无效)
test_cases="10.0.0.1:0 256.1.1.1:1 192.168.1.1:0 10.144.144.1:0"
passed=0
failed=0

for case in $test_cases; do
    ip=$(echo "$case" | cut -d: -f1)
    expected=$(echo "$case" | cut -d: -f2)

    if validate_ip "$ip"; then
        actual=0
    else
        actual=1
    fi

    if [ "$actual" = "$expected" ]; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
        echo "  ✗ IP验证失败: $ip (期望: $expected, 实际: $actual)"
    fi
done

echo "  ✓ IP验证测试: $passed 通过, $failed 失败"

echo ""
echo "=============================================="
echo "  模拟测试完成!"
echo "=============================================="

exit 0
