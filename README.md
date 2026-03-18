# ShellEasytier

ShellEasytier 是一个专为嵌入式设备（如小米路由器）设计的 EasyTier 客户端管理脚本，提供友好的交互式菜单界面。

## 功能特性

- 🚀 **一键安装** - 自动检测系统类型并安装
- 🌐 **网络配置** - 虚拟IP、网络名称、密钥配置
- 🔗 **对等节点** - 管理P2P连接节点
- 🌐 **子网代理** - 允许其他节点访问本地网络
- 📡 **中继服务器** - 配置中继服务器改善连接性
- 📊 **状态监控** - 实时查看运行状态和日志
- 🔄 **自启动** - 支持开机自启动（小米路由器/OpenWrt等）
- 🌍 **国际化** - 支持中英文界面

## 支持的系统

- 小米官方固件 / OpenWrt
- ASUS 路由器 (梅林固件)
- Padavan 固件
- 通用 Linux 系统
- Docker/容器环境

## 快速开始

### 一键安装

```sh
sh -c "$(curl -fsSL https://github.com/EasyTier/ShellEasytier/raw/main/install.sh)"
```

或使用 wget:

```sh
sh -c "$(wget -qO- https://github.com/EasyTier/ShellEasytier/raw/main/install.sh)"
```

### 手动安装

1. 下载安装包:
```sh
wget https://github.com/EasyTier/ShellEasytier/releases/latest/download/ShellEasytier.tar.gz
```

2. 解压到目标目录:
```sh
tar -zxf ShellEasytier.tar.gz -C /data/
```

3. 运行初始化:
```sh
cd /data/ShellEasytier
./scripts/init.sh
```

## 使用方法

启动菜单界面:
```sh
se
```

命令行操作:
```sh
se -s start    # 启动服务
se -s stop     # 停止服务
se -s restart  # 重启服务
se -s status   # 查看状态
```

## 配置说明

### 网络配置

- **虚拟IP**: EasyTier网络中的IP地址 (如 10.144.144.1)
- **DHCP模式**: 自动获取IP地址
- **网络名称**: 虚拟网络的标识
- **网络密钥**: 网络访问密码 (可选)

### 对等节点

添加其他 EasyTier 节点的连接地址:
- TCP: `tcp://192.168.1.100:11010`
- UDP: `udp://peer.example.com:11010`
- WebSocket: `ws://example.com:11010`

### 子网代理

允许其他节点访问本地子网:
- 示例: `192.168.1.0/24`

## 目录结构

```
ShellEasytier/
├── scripts/
│   ├── init.sh          # 初始化脚本
│   ├── menu.sh          # 主菜单入口
│   ├── libs/            # 工具库
│   ├── menus/           # 菜单功能
│   └── lang/            # 语言文件
├── bin/                 # EasyTier 二进制
├── configs/             # 配置文件
├── starts/              # 启动脚本
├── install.sh           # 安装脚本
└── version              # 版本文件
```

## 许可证

MIT License

## 开发测试

### Docker 测试

项目提供完整的 Docker 测试环境：

```sh
# 一键运行所有测试
sh scripts/docker-test.sh

# 或使用 Makefile
make docker-test

# 使用 docker-compose
docker-compose -f docker-compose.test.yml up --build
```

### 本地测试

```sh
# 运行自动化测试套件
sh test/test.sh

# 运行模拟环境测试
sh test/mock_test.sh

# 静态代码检查
make lint
```

### GitHub Actions CI

项目配置了自动化的 GitHub Actions 工作流：
- **CI 工作流**: 本地测试 + ShellCheck + Docker 测试
- **Docker 测试**: 多架构测试 (amd64/arm64/armv7)

## 相关项目

- [EasyTier](https://github.com/EasyTier/EasyTier) - 去中心化 VPN 组网工具
