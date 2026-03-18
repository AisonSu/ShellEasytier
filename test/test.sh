#!/bin/sh
# Copyright (C) ShellEasytier
# 测试脚本

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
EASYDIR="$(dirname "$TEST_DIR")"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
NC='\033[0m' # No Color

# 测试计数
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
run_test() {
    test_name="$1"
    test_cmd="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    printf "[%2d] %-40s " "$TESTS_TOTAL" "$test_name"

    if eval "$test_cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 显示测试结果
show_results() {
    echo "=============================================="
    echo -e "测试总数: $TESTS_TOTAL"
    echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "失败: ${RED}$TESTS_FAILED${NC}"
    echo "=============================================="

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}所有测试通过！${NC}"
        return 0
    else
        echo -e "${RED}存在失败的测试！${NC}"
        return 1
    fi
}

echo "=============================================="
echo "    ShellEasytier 测试套件"
echo "=============================================="
echo ""

# 1. 文件存在性测试
echo "[1] 文件存在性测试"
echo "----------------------------------------------"
run_test "主菜单存在" "[ -f $EASYDIR/scripts/menu.sh ]"
run_test "初始化脚本存在" "[ -f $EASYDIR/scripts/init.sh ]"
run_test "配置库存在" "[ -f $EASYDIR/scripts/libs/set_config.sh ]"
run_test "TUI布局库存在" "[ -f $EASYDIR/scripts/menus/tui_layout.sh ]"
run_test "中文语言文件存在" "[ -f $EASYDIR/scripts/lang/chs/menu.lang ]"
run_test "英文语言文件存在" "[ -f $EASYDIR/scripts/lang/en/menu.lang ]"
run_test "版本文件存在" "[ -f $EASYDIR/version ]"
echo ""

# 2. Shell 语法测试
echo "[2] Shell 语法测试"
echo "----------------------------------------------"
run_test "menu.sh 语法检查" "sh -n $EASYDIR/scripts/menu.sh"
run_test "init.sh 语法检查" "sh -n $EASYDIR/scripts/init.sh"
run_test "set_config.sh 语法检查" "sh -n $EASYDIR/scripts/libs/set_config.sh"
run_test "get_config.sh 语法检查" "sh -n $EASYDIR/scripts/libs/get_config.sh"
run_test "i18n.sh 语法检查" "sh -n $EASYDIR/scripts/libs/i18n.sh"
run_test "service.sh 语法检查" "sh -n $EASYDIR/scripts/libs/service.sh"
run_test "1_start.sh 语法检查" "sh -n $EASYDIR/scripts/menus/1_start.sh"
run_test "2_network.sh 语法检查" "sh -n $EASYDIR/scripts/menus/2_network.sh"
run_test "common.sh 语法检查" "sh -n $EASYDIR/scripts/menus/common.sh"
run_test "tui_layout.sh 语法检查" "sh -n $EASYDIR/scripts/menus/tui_layout.sh"
echo ""

# 3. 函数定义测试
echo "[3] 函数定义测试"
echo "----------------------------------------------"
run_test "setconfig 函数定义" "grep -q 'setconfig()' $EASYDIR/scripts/libs/set_config.sh"
run_test "load_lang 函数定义" "grep -q 'load_lang()' $EASYDIR/scripts/libs/i18n.sh"
run_test "content_line 函数定义" "grep -q 'content_line()' $EASYDIR/scripts/menus/tui_layout.sh"
run_test "msg_alert 函数定义" "grep -q 'msg_alert()' $EASYDIR/scripts/menus/common.sh"
run_test "start_easytier 函数定义" "grep -q 'start_easytier()' $EASYDIR/scripts/libs/service.sh"
run_test "validate_ip 函数定义" "grep -q 'validate_ip()' $EASYDIR/scripts/menus/2_network.sh"
echo ""

# 4. 配置文件格式测试
echo "[4] 配置文件格式测试"
echo "----------------------------------------------"
run_test "install.sh 语法检查" "sh -n $EASYDIR/install.sh"
run_test "build.sh 语法检查" "sh -n $EASYDIR/build.sh"
run_test "check_and_start.sh 语法检查" "sh -n $EASYDIR/scripts/check_and_start.sh"
echo ""

# 5. 语言文件完整性测试
echo "[5] 语言文件完整性测试"
echo "----------------------------------------------"
run_test "中文 common.lang 包含 COMMON_INPUT" "grep -q 'COMMON_INPUT=' $EASYDIR/scripts/lang/chs/common.lang"
run_test "中文 menu.lang 包含 MENU_WELCOME" "grep -q 'MENU_WELCOME=' $EASYDIR/scripts/lang/chs/menu.lang"
run_test "英文 common.lang 包含 COMMON_INPUT" "grep -q 'COMMON_INPUT=' $EASYDIR/scripts/lang/en/common.lang"
run_test "英文 menu.lang 包含 MENU_WELCOME" "grep -q 'MENU_WELCOME=' $EASYDIR/scripts/lang/en/menu.lang"
echo ""

# 6. 特殊字符测试
echo "[6] 特殊字符兼容性测试"
echo "----------------------------------------------"
run_test "文件无 Windows 换行符" "! find $EASYDIR/scripts -name '*.sh' -exec file {} \; | grep -q 'CRLF'"
run_test "文件无 BOM 头" "! find $EASYDIR/scripts -name '*.sh' -exec hexdump -C {} \; | head -1 | grep -q 'ef bb bf'"
echo ""

# 显示结果
show_results
exit $?
