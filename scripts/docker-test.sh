#!/bin/sh
# Copyright (C) ShellEasytier
# Docker 测试入口脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo "=============================================="
    echo "$1"
    echo "=============================================="
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker > /dev/null 2>&1; then
        print_error "Docker not found. Please install Docker first."
        exit 1
    fi

    if ! docker info > /dev/null 2>&1; then
        print_error "Docker daemon not running. Please start Docker."
        exit 1
    fi

    print_success "Docker is available"
}

# 构建测试镜像
build_image() {
    print_header "Building Docker Test Image"

    if docker build -f Dockerfile.test -t shelleasytier:test .; then
        print_success "Image built successfully"
    else
        print_error "Failed to build image"
        exit 1
    fi
}

# 运行测试
run_tests() {
    print_header "Running Docker Tests"

    if docker run --rm shelleasytier:test; then
        print_success "All tests passed"
        return 0
    else
        print_error "Some tests failed"
        return 1
    fi
}

# 运行交互式 shell
run_shell() {
    print_header "Starting Interactive Shell"
    print_info "Type 'exit' to quit"
    echo ""

    docker run --rm -it \
        -v "$PROJECT_ROOT":/app \
        --entrypoint /bin/sh \
        shelleasytier:test
}

# 运行特定测试
run_specific_test() {
    test_name="$1"
    print_header "Running: $test_name"

    case "$test_name" in
        syntax)
            docker run --rm --entrypoint /bin/sh shelleasytier:test -c \
                "find /app/scripts -name '*.sh' -exec sh -n {} \;"
            ;;
        shellcheck)
            docker run --rm --entrypoint /bin/sh shelleasytier:test -c \
                "find /app/scripts -name '*.sh' -exec shellcheck --shell=sh --exclude=SC2039,SC3043,SC3010,SC3028 {} \;"
            ;;
        automated)
            docker run --rm --entrypoint /bin/sh shelleasytier:test -c \
                "cd /app && sh test/test.sh"
            ;;
        mock)
            docker run --rm --entrypoint /bin/sh shelleasytier:test -c \
                "cd /app && sh test/mock_test.sh"
            ;;
        *)
            print_error "Unknown test: $test_name"
            echo "Available: syntax, shellcheck, automated, mock"
            exit 1
            ;;
    esac
}

# 清理资源
cleanup() {
    print_header "Cleaning Up"

    docker rmi -f shelleasytier:test 2>/dev/null || true
    docker system prune -f 2>/dev/null || true

    print_success "Cleanup completed"
}

# 主函数
main() {
    print_header "ShellEasytier Docker Test Runner"

    case "${1:-all}" in
        all)
            check_docker
            build_image
            run_tests
            ;;
        build)
            check_docker
            build_image
            ;;
        shell)
            check_docker
            build_image
            run_shell
            ;;
        test)
            check_docker
            run_tests
            ;;
        run)
            shift
            run_specific_test "$1"
            ;;
        clean)
            cleanup
            ;;
        help)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  all      - Build image and run all tests (default)"
            echo "  build    - Build Docker test image"
            echo "  test     - Run tests (requires built image)"
            echo "  shell    - Enter interactive shell"
            echo "  run      - Run specific test (syntax|shellcheck|automated|mock)"
            echo "  clean    - Clean up Docker resources"
            echo "  help     - Show this help"
            echo ""
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Run '$0 help' for usage"
            exit 1
            ;;
    esac
}

main "$@"
