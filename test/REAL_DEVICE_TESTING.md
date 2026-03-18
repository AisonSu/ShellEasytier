# ShellEasytier 实机测试指南

## 支持的设备

- **小米路由器** (官方固件 / OpenWrt)
- **ASUS 路由器** (梅林固件 / Asuswrt)
- **Padavan 固件** 路由器
- **OpenWrt** 设备
- **Docker/容器** 环境

## 快速开始

### 方法一：一键安装（推荐）

```sh
# 通过 SSH 连接到路由器
ssh root@192.168.31.1

# 一键安装
sh -c "$(curl -fsSL https://raw.githubusercontent.com/EasyTier/ShellEasytier/main/install.sh)"
```

### 方法二：本地安装包测试

```sh
# 1. 在电脑上构建安装包
cd ShellEasytier
sh build.sh

# 2. 复制到路由器（假设路由器 IP 是 192.168.31.1）
scp ShellEasytier.tar.gz root@192.168.31.1:/tmp/

# 3. SSH 到路由器安装
ssh root@192.168.31.1
cd /tmp
tar -zxf ShellEasytier.tar.gz -C /data/
/data/ShellEasytier/scripts/init.sh
```

### 方法三：开发测试（直接复制文件）

```sh
# 1. 确保路由器有 /data 或 /opt 目录且有足够空间
ssh root@192.168.31.1 "df -h /data"

# 2. 使用 rsync 同步开发代码（推荐）
rsync -avz --delete \
  --exclude='.git' \
  --exclude='test' \
  --exclude='.github' \
  ./ root@192.168.31.1:/data/ShellEasytier/

# 3. SSH 到路由器设置权限并运行
ssh root@192.168.31.1
chmod +x /data/ShellEasytier/scripts/*.sh
chmod +x /data/ShellEasytier/scripts/*/*.sh
/data/ShellEasytier/scripts/menu.sh
```

## 详细测试步骤

### 步骤 1：环境检查

```sh
# 检查系统类型
cat /etc/openwrt_release 2>/dev/null || cat /proc/version

# 检查架构
uname -m

# 检查存储空间
df -h

# 检查内存
free

# 检查是否有 curl/wget
which curl || which wget
```

### 步骤 2：安装测试

```sh
# 运行安装脚本
sh /data/ShellEasytier/install.sh

# 安装完成后检查
echo $PATH | grep -q ShellEasytier && echo "安装成功" || echo "需要重新登录"
```

### 步骤 3：初始化配置

```sh
# 运行初始化（自动检测系统类型）
/data/ShellEasytier/scripts/init.sh

# 或者手动指定系统类型
# 小米: /data/ShellEasytier/scripts/init.sh xiaomi
# OpenWrt: /data/ShellEasytier/scripts/init.sh openwrt
# 通用: /data/ShellEasytier/scripts/init.sh general
```

### 步骤 4：启动菜单测试

```sh
# 方式 1: 使用别名
se

# 方式 2: 直接运行
/data/ShellEasytier/scripts/menu.sh

# 方式 3: 命令行模式
se -s status    # 查看状态
se -s start     # 启动服务
se -s stop      # 停止服务
```

## 功能测试清单

### 基础功能

- [ ] 菜单正常显示（中文/英文）
- [ ] 网络配置（虚拟 IP、网络名称、密钥）
- [ ] 对等节点添加/删除
- [ ] 子网代理启用/禁用
- [ ] 中继服务器配置
- [ ] 状态查看和日志
- [ ] 升级功能

### 服务管理

- [ ] 启动 EasyTier 服务
- [ ] 停止 EasyTier 服务
- [ ] 重启 EasyTier 服务
- [ ] 开机自启动设置
- [ ] 配置修改后自动重启提示

### 配置持久化

```sh
# 检查配置是否保存
cat /data/ShellEasytier/configs/ShellEasytier.cfg

# 检查开机启动脚本
cat /etc/init.d/shelleasytier 2>/dev/null || \
cat /etc/rc.d/S99shelleasytier 2>/dev/null
```

## 常见问题

### 问题 1: 无法启动菜单

```
-sh: se: not found
```

**解决**:
```sh
# 方法 1: 重新加载 shell 配置
source /etc/profile

# 方法 2: 直接运行完整路径
/data/ShellEasytier/scripts/menu.sh

# 方法 3: 手动添加别名
alias se='/data/ShellEasytier/scripts/menu.sh'
```

### 问题 2: EasyTier 二进制下载失败

```
Download failed: easytier-linux-mipsel
```

**解决**:
```sh
# 检查架构
uname -m

# 手动下载对应版本
# 访问 https://github.com/EasyTier/EasyTier/releases
# 下载对应架构的二进制到 /data/ShellEasytier/bin/

# 设置权限
chmod +x /data/ShellEasytier/bin/easytier-linux-*
```

### 问题 3: 没有 TUN 设备

```
Error: failed to create TUN device
```

**解决**:
```sh
# 检查 TUN 模块
ls /dev/net/tun

# 如果没有，尝试加载模块
modprobe tun

# 或者使用无 TUN 模式（性能较低）
# 在菜单中选择 "无 TUN 模式"
```

### 问题 4: 端口被占用

```
Error: Address already in use
```

**解决**:
```sh
# 查看占用端口的进程
netstat -tlnp | grep 11010

# 停止冲突的服务
killall easytier-core 2>/dev/null

# 修改监听端口
se  # 进入菜单 → 网络配置 → 监听端口
```

### 问题 5: 存储空间不足

```
No space left on device
```

**解决**:
```sh
# 查看空间使用
df -h

# 清理临时文件
rm -rf /tmp/ShellEasytier*

# 安装到更大的分区（如 USB）
# 修改 install.sh 中的安装路径
```

## 调试技巧

### 启用调试模式

```sh
# 在脚本开头添加
set -x

# 或者运行时
sh -x /data/ShellEasytier/scripts/menu.sh
```

### 查看详细日志

```sh
# EasyTier 日志
tail -f /data/ShellEasytier/configs/easytier.log

# 系统日志
tail -f /var/log/messages
dmesg | grep -i easytier
```

### 检查配置文件

```sh
# 查看当前配置
cat /data/ShellEasytier/configs/ShellEasytier.cfg

# 检查格式
grep -E '^[A-Z_]+=.*$' /data/ShellEasytier/configs/ShellEasytier.cfg
```

## 性能测试

### 网络性能

```sh
# 1. 在路由器上启动 EasyTier
se -s start

# 2. 在 PC 上安装 EasyTier 并加入同一网络
# 3. 测试连接
ping 10.144.144.1  # 路由器虚拟 IP

# 4. 测试带宽
iperf3 -c 10.144.144.1
```

### 资源占用

```sh
# 查看 CPU/内存占用
top | grep easytier

# 更详细的统计
ps | grep easytier
cat /proc/$(pidof easytier-core)/status
```

## 安全测试

### 配置权限

```sh
# 检查配置文件的权限
ls -la /data/ShellEasytier/configs/

# 确保敏感文件只有 root 可读
chmod 600 /data/ShellEasytier/configs/ShellEasytier.cfg
```

### 网络隔离测试

```sh
# 测试是否只有授权节点可以连接
# 1. 使用错误的网络密钥尝试连接
# 2. 确认连接被拒绝
```

## 清理测试环境

```sh
# 停止服务
se -s stop

# 卸载
/data/ShellEasytier/scripts/menus/uninstall.sh

# 或者手动清理
rm -rf /data/ShellEasytier
rm -f /etc/init.d/shelleasytier
rm -f /etc/rc.d/S99shelleasytier
```

## 测试报告模板

```markdown
## 设备信息
- 型号:
- 固件:
- 架构:
- 存储:
- 内存:

## 测试项目
| 功能 | 结果 | 备注 |
|------|------|------|
| 安装 | ✅/❌ | |
| 启动菜单 | ✅/❌ | |
| 网络配置 | ✅/❌ | |
| 服务启动 | ✅/❌ | |
| 开机自启 | ✅/❌ | |

## 问题描述

## 日志输出
```
```
```
