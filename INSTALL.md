# 安装指南

## 系统要求

### 硬件要求
- 内存: 至少 512MB RAM
- 存储: 至少 100MB 可用空间
- 网络: 可访问 OpenClaw 网关

### 软件要求
- **操作系统**: Linux (Ubuntu/Debian/CentOS)
- **Python**: 3.7 或更高版本
- **OpenClaw**: 2026.4.2 或更高版本
- **依赖包**: 
  - `jq` (JSON处理)
  - `curl` (HTTP客户端)
  - `python3-venv` (Python虚拟环境，可选)

## 安装步骤

### 步骤1：检查系统要求
```bash
# 检查Python版本
python3 --version

# 检查OpenClaw版本
openclaw --version

# 检查依赖工具
which jq curl python3
```

### 步骤2：安装技能
```bash
# 方法A：从现有位置使用（已安装）
cd ~/.openclaw/skills/multi-window-memory-sync

# 方法B：复制到技能目录（如需部署到其他位置）
cp -r multi-window-memory-sync ~/.openclaw/skills/
```

### 步骤3：设置权限
```bash
cd ~/.openclaw/skills/multi-window-memory-sync
chmod +x scripts/*.sh
chmod +x scripts/*.py
```

### 步骤4：验证安装
```bash
# 检查技能结构
ls -la

# 测试脚本可执行性
./scripts/start-all.sh test

# 检查配置文件
cat config/sync-config.json | jq .
```

## 配置说明

### 基本配置
编辑 `config/sync-config.json` 文件：
```json
{
  "config": {
    "sync_interval_seconds": 5,      # 同步间隔（秒）
    "web_monitor_port": 26710,       # Web监控端口
    "enabled": true                  # 是否启用
  }
}
```

### 环境变量
```bash
# 设置同步间隔
export SYNC_INTERVAL=10

# 设置Web监控端口
export WEB_PORT=26711

# 启动时使用环境变量
SYNC_INTERVAL=10 WEB_PORT=26711 ./scripts/start-all.sh start
```

## 首次运行

### 启动系统
```bash
cd ~/.openclaw/skills/multi-window-memory-sync

# 启动完整系统
./scripts/start-all.sh start

# 或分步启动
./scripts/start-all.sh sync-only    # 只启动同步守护进程
./scripts/start-all.sh web-only     # 只启动Web监控
```

### 验证运行状态
```bash
# 检查进程状态
./scripts/start-all.sh status

# 检查Web监控
curl http://localhost:26710

# 检查记忆文件
tail -10 ~/.openclaw/workspace/MEMORY.md
```

## 开机自启动

### 方法A：使用systemd（推荐）
创建 `/etc/systemd/system/memory-sync.service`：
```ini
[Unit]
Description=Multi-Window Memory Sync Service
After=network.target openclaw-gateway.service

[Service]
Type=simple
User=root
WorkingDirectory=/root/.openclaw/skills/multi-window-memory-sync
ExecStart=/root/.openclaw/skills/multi-window-memory-sync/scripts/start-all.sh start
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable memory-sync
sudo systemctl start memory-sync
sudo systemctl status memory-sync
```

### 方法B：使用crontab
```bash
# 编辑crontab
crontab -e

# 添加启动命令（系统启动时运行）
@reboot cd /root/.openclaw/skills/multi-window-memory-sync && ./scripts/start-all.sh start > /tmp/memory-sync-startup.log 2>&1
```

### 方法C：使用rc.local
编辑 `/etc/rc.local`：
```bash
cd /root/.openclaw/skills/multi-window-memory-sync
./scripts/start-all.sh start &
```

## 多节点部署

### 主从架构
```bash
# 主节点（运行守护进程和Web监控）
./scripts/start-all.sh start

# 从节点（只运行同步客户端）
./scripts/sync-simple-daemon.sh start
```

### 负载均衡
```bash
# 在不同端口启动多个实例
WEB_PORT=26710 ./scripts/start-all.sh start
WEB_PORT=26711 ./scripts/start-all.sh start
WEB_PORT=26712 ./scripts/start-all.sh start
```

## 升级指南

### 备份现有配置
```bash
# 备份配置文件
cp -r ~/.openclaw/skills/multi-window-memory-sync/config /tmp/memory-sync-config-backup

# 备份记忆文件
cp ~/.openclaw/workspace/MEMORY.md ~/.openclaw/workspace/MEMORY.md.backup.$(date +%s)
```

### 更新技能
```bash
# 停止当前服务
cd ~/.openclaw/skills/multi-window-memory-sync
./scripts/start-all.sh stop

# 更新文件（假设新版本在 /tmp/memory-sync-new）
cp -r /tmp/memory-sync-new/* .

# 恢复配置
cp -r /tmp/memory-sync-config-backup/* config/

# 启动新版本
./scripts/start-all.sh start
```

## 卸载

### 完全卸载
```bash
# 停止服务
cd ~/.openclaw/skills/multi-window-memory-sync
./scripts/start-all.sh stop

# 删除技能目录
rm -rf ~/.openclaw/skills/multi-window-memory-sync

# 清理相关文件（可选）
rm -f ~/.openclaw/workspace/.sync_state_*.json
rm -rf ~/.openclaw/workspace/sync_logs
rm -rf ~/.openclaw/workspace/memory_backups

# 删除systemd服务（如果使用了）
sudo systemctl stop memory-sync
sudo systemctl disable memory-sync
sudo rm /etc/systemd/system/memory-sync.service
sudo systemctl daemon-reload
```

### 部分卸载（保留数据）
```bash
# 只停止服务，保留文件和配置
cd ~/.openclaw/skills/multi-window-memory-sync
./scripts/start-all.sh stop

# 数据文件保留在：
# - ~/.openclaw/workspace/MEMORY.md
# - ~/.openclaw/workspace/.sync_state_*.json
# - ~/.openclaw/workspace/sync_logs/
# - ~/.openclaw/workspace/memory_backups/
```

## 故障排除

### 安装问题
```bash
# 检查Python模块
python3 -c "import json, subprocess, time, signal, threading"

# 检查OpenClaw连接
openclaw sessions --active 5 --json 2>&1 | head -5

# 检查端口占用
netstat -tlnp | grep :26710
```

### 权限问题
```bash
# 修复文件权限
chmod -R 755 ~/.openclaw/skills/multi-window-memory-sync/scripts
chmod 644 ~/.openclaw/skills/multi-window-memory-sync/config/*.json

# 检查日志目录权限
mkdir -p ~/.openclaw/workspace/sync_logs
chmod 755 ~/.openclaw/workspace/sync_logs
```

## 支持

如需帮助，请：
1. 查看日志文件
2. 检查系统要求
3. 参考README.md文档
4. 通过OpenClaw社区寻求支持