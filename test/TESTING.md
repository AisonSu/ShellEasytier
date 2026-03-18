# ShellEasytier 测试指南

## 1. 自动化测试

### 1.1 快速测试
```sh
cd ShellEasytier
sh test/test.sh
```

### 1.2 测试覆盖项
- [x] 文件存在性检查
- [x] Shell 语法验证 (`sh -n`)
- [x] 函数定义检查
- [x] 配置文件格式
- [x] 语言文件完整性
- [x] 特殊字符兼容性 (CRLF/BOM)

## 2. 手动功能测试

### 2.1 语法验证
```sh
# 验证所有 shell 脚本语法
find scripts -name "*.sh" -exec sh -n {} \; 2>&1 | grep -v "^$"
```

### 2.2 模拟运行测试
```sh
# 设置测试环境
export EASYDIR=/tmp/test_shelleasytier
mkdir -p $EASYDIR/configs
mkdir -p $EASYDIR/scripts

# 复制文件
cp -r scripts/* $EASYDIR/scripts/

# 模拟初始化
cd $EASYDIR
echo "1.0.0" > version
echo "chs" > configs/i18n.cfg
echo "# Config" > configs/ShellEasytier.cfg

# 测试配置读取
. $EASYDIR/scripts/libs/get_config.sh
echo "TMPDIR: $EASY_TMPDIR"

# 测试配置写入
. $EASYDIR/scripts/libs/set_config.sh
setconfig TEST_KEY "test_value"
cat $EASYDIR/configs/ShellEasytier.cfg | grep TEST_KEY

# 测试国际化
. $EASYDIR/scripts/libs/i18n.sh
load_lang common
echo "Input prompt: $COMMON_INPUT"
```

### 2.3 菜单界面测试
```sh
# 测试 TUI 布局
cd $EASYDIR
. scripts/menus/tui_layout.sh
. scripts/menus/common.sh

# 显示测试框
line_break
separator_line "="
content_line "测试标题"
content_line "\033[32m绿色文本\033[0m"
content_line "中文测试：欢迎来到 ShellEasytier"
separator_line "="

# 测试消息框
msg_alert -t 2 "这是一条测试消息"
```

## 3. 集成测试

### 3.1 Docker 环境测试
```dockerfile
# Dockerfile.test
FROM alpine:latest

RUN apk add --no-cache bash curl wget

WORKDIR /test
COPY . /test/ShellEasytier/

# 运行测试
RUN sh /test/ShellEasytier/test/test.sh
```

构建并运行:
```sh
docker build -f Dockerfile.test -t shelleasytier-test .
docker run shelleasytier-test
```

### 3.2 OpenWrt 模拟测试
```sh
# 使用 OpenWrt SDK
# 1. 安装 OpenWrt SDK
git clone https://git.openwrt.org/openwrt/openwrt.git
cd openwrt

# 2. 创建测试包
cat > package/shelleasytier/test.sh << 'EOF'
#!/bin/sh
. /lib/functions.sh
# 测试各个功能模块
EOF
```

## 4. 真实环境测试

### 4.1 小米路由器测试
```sh
# 1. SSH 登录路由器
ssh root@192.168.31.1

# 2. 创建测试目录
mkdir -p /data/test_se
cd /data/test_se

# 3. 上传文件 (从本地)
scp -r ShellEasytier/* root@192.168.31.1:/data/test_se/

# 4. 在路由器上测试
cd /data/test_se
sh scripts/init.sh
sh scripts/menu.sh -h
```

### 4.2 安装流程测试
```sh
# 测试安装脚本
sh -x install.sh << EOF
1
EOF

# 验证安装结果
ls -la /data/ShellEasytier/
ls -la /data/ShellEasytier/scripts/
se -h
```

## 5. 功能测试清单

### 5.1 网络配置
- [ ] 设置虚拟 IP (静态)
- [ ] 启用 DHCP 模式
- [ ] 设置网络名称
- [ ] 设置网络密钥
- [ ] 设置监听端口
- [ ] 设置 RPC 端口

### 5.2 对等节点管理
- [ ] 添加 TCP 节点
- [ ] 添加 UDP 节点
- [ ] 添加 WebSocket 节点
- [ ] 删除节点
- [ ] 查看节点列表

### 5.3 子网代理
- [ ] 添加代理子网
- [ ] 删除代理子网
- [ ] 启用/禁用代理

### 5.4 中继服务器
- [ ] 添加中继服务器
- [ ] 启用公共中继
- [ ] 禁用公共中继

### 5.5 服务管理
- [ ] 启动服务
- [ ] 停止服务
- [ ] 查看状态
- [ ] 查看日志

### 5.6 自启动
- [ ] 设置开机自启动
- [ ] 取消开机自启动
- [ ] 重启后验证

## 6. 边界条件测试

### 6.1 输入验证
```sh
# 测试无效 IP
validate_ip "256.1.1.1"    # 应失败
validate_ip "10.0.0"       # 应失败
validate_ip "10.0.0.1"     # 应成功

# 测试无效端口
validate_port "0"          # 应失败
validate_port "70000"      # 应失败
validate_port "11010"      # 应成功
```

### 6.2 异常情况
- [ ] 缺少配置文件时的处理
- [ ] 网络不可用时下载 EasyTier 的处理
- [ ] 权限不足时的处理
- [ ] 磁盘空间不足时的处理

## 7. 性能测试

### 7.1 启动时间
```sh
time sh scripts/menu.sh -s start
```

### 7.2 内存使用
```sh
# 监控内存
watch -n 1 'cat /proc/$(pidof easytier-core)/status | grep -E "VmRSS|VmSize"'
```

## 8. 调试技巧

### 8.1 启用调试模式
```sh
# 在脚本顶部添加
set -x

# 或运行时
sh -x scripts/menu.sh
```

### 8.2 日志记录
```sh
# 查看详细日志
tail -f /tmp/ShellEasytier/easytier.log

# 导出配置
cat /data/ShellEasytier/configs/ShellEasytier.cfg
```

### 8.3 常见问题排查
```sh
# 1. 检查依赖
which curl wget tar unzip

# 2. 检查权限
ls -la /data/ShellEasytier/scripts/*.sh

# 3. 检查进程
ps | grep easytier

# 4. 检查端口
netstat -tlnp | grep 11010
```

## 9. 持续集成

### 9.1 GitHub Actions 配置
```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install shellcheck
        run: sudo apt-get install -y shellcheck
      - name: Run shellcheck
        run: find scripts -name "*.sh" | xargs shellcheck
      - name: Run test suite
        run: sh test/test.sh
```

### 9.2 本地预提交检查
```sh
# 创建 pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# 运行测试
sh test/test.sh || exit 1
EOF
chmod +x .git/hooks/pre-commit
```

## 10. 发布前检查清单

- [ ] 所有自动化测试通过
- [ ] 版本号已更新
- [ ] CHANGELOG 已更新
- [ ] 文档已更新
- [ ] 安装脚本测试通过
- [ ] 卸载功能测试通过
- [ ] 至少在一个真实设备上测试通过
