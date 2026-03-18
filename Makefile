.PHONY: help test docker-test docker-build clean lint shellcheck

# 默认目标
help:
	@echo "ShellEasytier Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make test          - Run local test suite"
	@echo "  make docker-test   - Run tests in Docker"
	@echo "  make docker-build  - Build Docker test image"
	@echo "  make docker-shell  - Enter Docker container for debugging"
	@echo "  make lint          - Run shellcheck"
	@echo "  make clean         - Clean test artifacts"
	@echo ""

# 本地测试
test:
	@echo "Running local tests..."
	@sh test/test.sh
	@echo ""
	@sh test/mock_test.sh

# Shellcheck 静态分析
lint:
	@echo "Running shellcheck..."
	@find scripts -name "*.sh" | xargs shellcheck --shell=sh --severity=warning

# Docker 测试
docker-test: docker-build
	@echo "Running Docker tests..."
	@docker run --rm shelleasytier:test

# 构建 Docker 镜像
docker-build:
	@echo "Building Docker test image..."
	@docker build -f Dockerfile.test -t shelleasytier:test .

# 进入 Docker 容器调试
docker-shell:
	@echo "Starting Docker shell..."
	@docker run --rm -it -v $(PWD):/app --entrypoint /bin/sh shelleasytier:test

# 使用 docker-compose 测试
docker-compose-test:
	@echo "Running tests with docker-compose..."
	@docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit

# 清理
clean:
	@echo "Cleaning test artifacts..."
	@rm -rf test-results/
	@docker rmi -f shelleasytier:test 2>/dev/null || true

# CI 完整测试流程
ci: lint test
	@echo "CI tests completed"
