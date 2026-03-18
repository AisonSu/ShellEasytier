# Windows 下 Docker 测试指南

## 前提条件

### 1. 安装 Docker Desktop

1. 下载 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. 安装时选择 **WSL2 后端**（推荐）
3. 安装完成后重启电脑

### 2. 验证 Docker 安装

打开 PowerShell 或 CMD：

```powershell
# 检查 Docker 版本
docker --version
# 预期输出: Docker version 24.x.x, build xxx

# 检查 Docker Compose
docker-compose --version
# 预期输出: Docker Compose version v2.x.x

# 验证 Docker 运行状态
docker info
```

## 测试方法

### 方法一：使用 PowerShell / CMD

```powershell
# 进入项目目录
cd C:\Users\aison\code\ShellCrash\ShellEasytier

# 方式1: 使用 docker-test.sh (通过 Git Bash)
"C:\Program Files\Git\bin\bash.exe" scripts/docker-test.sh

# 方式2: 直接使用 Docker 命令
docker build -f Dockerfile.test -t shelleasytier:test .
docker run --rm shelleasytier:test

# 方式3: 使用 docker-compose
docker-compose -f docker-compose.test.yml up --build
```

### 方法二：使用 WSL2 (推荐)

在 WSL2 Ubuntu 中测试性能更好：

```bash
# 进入 WSL2
wsl

# 进入项目目录 (WSL 会挂载 Windows 磁盘)
cd /mnt/c/Users/aison/code/ShellCrash/ShellEasytier

# 运行测试
sh scripts/docker-test.sh

# 或手动构建测试
docker build -f Dockerfile.test -t shelleasytier:test .
docker run --rm shelleasytier:test
```

### 方法三：使用 Makefile (需要安装 make)

Windows 安装 make：

```powershell
# 通过 Chocolatey 安装
choco install make

# 或通过 winget
winget install GnuWin32.Make
```

然后使用：

```powershell
# 进入项目目录
cd C:\Users\aison\code\ShellCrash\ShellEasytier

# 查看可用目标
make help

# 运行测试
make docker-test

# 进入调试 shell
make docker-shell
```

## 详细测试步骤

### 步骤 1：构建测试镜像

```powershell
cd C:\Users\aison\code\ShellCrash\ShellEasytier
docker build -f Dockerfile.test -t shelleasytier:test .
```

### 步骤 2：运行完整测试

```powershell
docker run --rm shelleasytier:test
```

预期输出：
```
==============================================
    ShellEasytier Docker 测试环境
==============================================

----------------------------------------------
Running: Shell Syntax Check
----------------------------------------------
...
✓ Shell Syntax Check PASSED

...
==============================================
              测试结果汇总
==============================================
通过: 8
失败: 0
==============================================
所有测试通过！
```

### 步骤 3：运行特定测试

```powershell
# 仅运行语法检查
docker run --rm --entrypoint /bin/sh shelleasytier:test -c "
  find /app/scripts -name '*.sh' -exec sh -n {} \;
"

# 仅运行 shellcheck
docker run --rm --entrypoint /bin/sh shelleasytier:test -c "
  find /app/scripts -name '*.sh' -exec shellcheck --shell=sh {} \;
"

# 仅运行自动化测试
docker run --rm --entrypoint /bin/sh shelleasytier:test -c "
  cd /app && sh test/test.sh
"
```

### 步骤 4：交互式调试

```powershell
# 进入容器内部调试
docker run --rm -it -v ${PWD}:/app --entrypoint /bin/sh shelleasytier:test

# 在容器内可以手动测试
/app # cd /app
/app # sh scripts/menu.sh -h
/app # sh test/test.sh
```

## 常见问题

### 问题 1: Docker Desktop 未启动

```
error during connect: this error may indicate that the docker daemon is not running
```

**解决**: 启动 Docker Desktop 应用，等待左下角显示 "Engine running"

### 问题 2: WSL2 集成未启用

```
The command 'docker' could not be found in this WSL 2 distro.
```

**解决**: 在 Docker Desktop 设置中启用 WSL2 集成：
1. 打开 Docker Desktop
2. Settings → Resources → WSL Integration
3. 启用 Ubuntu (或你的 WSL2 发行版)
4. Apply & Restart

### 问题 3: 文件换行符问题 (CRLF)

```
/bin/sh^M: bad interpreter
```

**解决**: 在 Git Bash 中转换换行符：

```bash
# 安装 dos2unix
apt-get install dos2unix

# 转换文件
dos2unix scripts/*.sh
find scripts -name "*.sh" -exec dos2unix {} \;
```

或在 Git 中设置：

```bash
git config --global core.autocrlf false
```

### 问题 4: 权限不足

```powershell
# 以管理员身份运行 PowerShell
# 右键点击 PowerShell → 以管理员身份运行
```

## 高级用法

### 使用 VS Code Dev Containers

1. 安装 VS Code 插件 "Dev Containers"
2. 在项目目录创建 `.devcontainer/devcontainer.json`：

```json
{
  "name": "ShellEasytier Test",
  "dockerFile": "../Dockerfile.test",
  "context": "..",
  "settings": {
    "terminal.integrated.shell.linux": "/bin/sh"
  },
  "postCreateCommand": "sh test/test.sh"
}
```

3. 按 F1 → "Dev Containers: Reopen in Container"

### 多架构测试

Windows 上测试其他架构（需要 Docker Desktop 配置）：

```powershell
# 启用 experimental features
# Docker Desktop → Settings → Features → Use containerd

# 构建多架构镜像
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -f Dockerfile.test -t shelleasytier:test .
```

### 持续本地测试

使用文件监视自动测试：

```powershell
# 安装 watchexec (通过 scoop)
scoop install watchexec

# 监视文件变化并自动测试
watchexec -e sh "docker run --rm shelleasytier:test"
```

## 性能对比

| 方式 | 首次构建 | 再次运行 | 推荐度 |
|------|----------|----------|--------|
| PowerShell + Docker | 慢 | 快 | ⭐⭐⭐ |
| WSL2 + Docker | 快 | 快 | ⭐⭐⭐⭐⭐ |
| Git Bash + Docker | 慢 | 快 | ⭐⭐⭐ |
| VS Code Dev Container | 中等 | 快 | ⭐⭐⭐⭐ |

## 推荐工作流

1. **日常开发**: 使用 WSL2 + Docker
2. **IDE 集成**: 使用 VS Code + Dev Containers 插件
3. **CI/CD 验证**: 使用 PowerShell 直接运行 Docker 命令
