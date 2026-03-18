# 实机测试快速参考

## 1. 复制到路由器
```sh
# 使用 rsync（推荐，支持增量同步）
rsync -avz --delete --exclude='.git' --exclude='test' \
  ./ root@192.168.31.1:/data/ShellEasytier/

# 或使用 scp（首次使用）
scp -r ShellEasytier root@192.168.31.1:/data/
```

## 2. 路由器上运行
```sh
ssh root@192.168.31.1
cd /data/ShellEasytier
chmod +x scripts/*.sh scripts/*/*.sh
./scripts/menu.sh
```

## 3. 基本测试流程
```
1. 启动菜单 → 检查界面显示
2. 网络配置 → 设置虚拟 IP
3. 添加对等节点 → 输入测试节点
4. 启动服务 → 查看状态
5. 检查连接 → ping 虚拟网络
```

## 4. 快速命令
```sh
se                    # 启动菜单
se -s start           # 启动服务
se -s status          # 查看状态
tail -f configs/*.log # 查看日志
```

## 5. 调试
```sh
# 调试模式
sh -x scripts/menu.sh

# 检查进程
ps | grep easytier

# 检查端口
netstat -tlnp | grep 11010
```
