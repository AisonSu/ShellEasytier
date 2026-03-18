# Copyright (C) ShellEasytier
# Windows PowerShell Docker 测试脚本

param(
    [Parameter()]
    [ValidateSet("all", "build", "test", "shell", "clean", "help")]
    [string]$Command = "all",

    [Parameter()]
    [string]$TestName = ""
)

$ErrorActionPreference = "Stop"

# 颜色定义
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Blue }
function Write-Header { param($Message)
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
}

# 检查 Docker
function Test-Docker {
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -ne 0) { throw "Docker not found" }
        Write-Success "Docker found: $dockerVersion"

        docker info >$null 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Docker daemon not running" }
        Write-Success "Docker daemon is running"
    }
    catch {
        Write-Error "Docker check failed: $_"
        Write-Host ""
        Write-Host "Please install Docker Desktop:" -ForegroundColor Yellow
        Write-Host "https://www.docker.com/products/docker-desktop/" -ForegroundColor Blue
        exit 1
    }
}

# 获取项目根目录
function Get-ProjectRoot {
    $scriptPath = $PSScriptRoot
    return Split-Path $scriptPath -Parent
}

# 构建镜像
function Build-Image {
    Write-Header "Building Docker Test Image"
    $projectRoot = Get-ProjectRoot

    docker build -f "$projectRoot\Dockerfile.test" -t shelleasytier:test "$projectRoot"

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Image built successfully"
    } else {
        Write-Error "Failed to build image"
        exit 1
    }
}

# 运行测试
function Run-Tests {
    Write-Header "Running Docker Tests"
    docker run --rm shelleasytier:test

    if ($LASTEXITCODE -eq 0) {
        Write-Success "All tests passed"
    } else {
        Write-Error "Some tests failed"
        exit 1
    }
}

# 运行交互式 shell
function Run-Shell {
    Write-Header "Starting Interactive Shell"
    Write-Info "Type 'exit' to quit"
    Write-Host ""

    $projectRoot = Get-ProjectRoot
    docker run --rm -it -v "${projectRoot}:/app" --entrypoint /bin/sh shelleasytier:test
}

# 清理资源
function Clear-Resources {
    Write-Header "Cleaning Up"

    docker rmi -f shelleasytier:test 2>$null
    docker system prune -f 2>$null | Out-Null

    Write-Success "Cleanup completed"
}

# 显示帮助
function Show-Help {
    Write-Host @"
ShellEasytier Docker Test Script for Windows

Usage: .\docker-test.ps1 [Command] [Options]

Commands:
    all      Build image and run all tests (default)
    build    Build Docker test image only
    test     Run tests (requires built image)
    shell    Enter interactive shell for debugging
    clean    Clean up Docker resources
    help     Show this help message

Examples:
    .\docker-test.ps1                    # Run all tests
    .\docker-test.ps1 build              # Build image only
    .\docker-test.ps1 test               # Run tests only
    .\docker-test.ps1 shell              # Interactive shell
    .\docker-test.ps1 clean              # Clean up

Prerequisites:
    - Docker Desktop for Windows
    - WSL2 backend (recommended)
"@
}

# 主函数
function Main {
    Write-Header "ShellEasytier Docker Test (Windows)"

    switch ($Command) {
        "all" {
            Test-Docker
            Build-Image
            Run-Tests
        }
        "build" {
            Test-Docker
            Build-Image
        }
        "test" {
            Test-Docker
            Run-Tests
        }
        "shell" {
            Test-Docker
            Build-Image
            Run-Shell
        }
        "clean" {
            Clear-Resources
        }
        "help" {
            Show-Help
        }
    }
}

# 执行主函数
Main
