# 多窗口记忆同步系统

## 概述
实时同步多个聊天窗口之间的记忆，解决跨会话记忆隔离问题。每5秒自动更新一次，确保所有窗口都能看到最新的聊天历史和记忆。

## 功能特性
- ✅ **5秒自动同步** - 定时检测并更新记忆
- ✅ **跨窗口记忆共享** - 在不同聊天会话间同步 MEMORY.md 内容
- ✅ **实时可见性** - 随时查看其他窗口的聊天状态
- ✅ **Web监控界面** - 实时状态监控 (端口: 26710)
- ✅ **自动备份系统** - 记忆文件版本控制
- ✅ **冲突解决** - 处理多个窗口同时修改记忆的冲突
- ✅ **完整的启动管理** - 一键启动/停止/重启

## 快速开始

### 安装
```bash
# 技能已安装在: ~/.openclaw/skills/multi-window-memory-sync
```

### 启动系统
```bash
cd ~/.openclaw/skills/multi-window-memory-sync
./scripts/start-all.sh start
```

### 访问监控界面
- **本地访问**: http://localhost:26710
- **外部访问**: http://81.71.7.59:26710
- **状态API**: http://81.71.7.59:26710/status

## 系统架构

### 核心组件
1. **Python守护进程** (`real-daemon.py`) - 主同步引擎
2. **Web监控界面** (`web-monitor.py`) - 状态监控
3. **启动管理脚本** (`start-all.sh`) - 系统管理
4. **配置系统** (`config/`) - 配置文件

### 工作流程
```
用户修改记忆 → 守护进程检测 → 更新同步状态 → Web监控显示
     ↓
  5秒自动循环
```

## 详细使用

### 管理命令
```bash
# 启动完整系统
./scripts/start-all.sh start

# 查看状态
./scripts/start-all.sh status

# 停止系统
./scripts/start-all.sh stop

# 重启系统
./scripts/start-all.sh restart

# 只启动同步守护进程
./scripts/start-all.sh sync-only

# 只启动Web监控
./scripts/start-all.sh web-only

# 清理旧文件
./scripts/start-all.sh cleanup
```

### 手动测试
```bash
# 测试单次同步
python3 ./scripts/real-daemon.py start

# 查看Python守护进程状态
python3 ./scripts/real-daemon.py status

# 停止Python守护进程
python3 ./scripts/real-daemon.py stop
```

## 配置说明

### 同步间隔
默认同步间隔为5秒，可通过环境变量修改：
```bash
SYNC_INTERVAL=10 ./scripts/start-all.sh start
```

### 监控端口
默认Web监控端口为26710，可在脚本中修改。

### 文件位置
- **记忆文件**: `~/.openclaw/workspace/MEMORY.md`
- **状态文件**: `~/.openclaw/workspace/.sync_state_*.json`
- **日志文件**: `~/.openclaw/workspace/sync_logs/`
- **备份文件**: `~/.openclaw/workspace/memory_backups/`

## 技术实现

### 会话检测
使用OpenClaw的`sessions`命令获取活跃会话列表：
```bash
openclaw sessions --active 30 --json
```

### 记忆同步
1. 读取当前记忆文件内容
2. 更新同步状态部分
3. 保持其他记忆内容不变
4. 记录同步历史

### 错误处理
- 会话获取超时处理
- 文件读写错误恢复
- 进程异常重启机制
- 日志记录和监控

## 开发说明

### 项目结构
```
multi-window-memory-sync/
├── README.md                    # 本文档
├── SKILL.md                     # OpenClaw技能定义
├── config/                      # 配置文件目录
│   └── sync-config.json         # 同步配置示例
└── scripts/                     # 脚本文件
    ├── real-daemon.py           # Python守护进程（主程序）
    ├── web-monitor.py           # Web监控界面
    ├── start-all.sh             # 完整启动管理
    ├── sync-complete.sh         # 完整版同步脚本
    ├── sync-stable.sh           # 稳定版同步脚本
    ├── sync-simple-daemon.sh    # 简单守护进程
    └── sync-simple.sh           # 简单同步脚本
```

### 扩展开发
1. **添加真正的消息发送** - 替换模拟发送为真实API调用
2. **增强冲突解决** - 实现更复杂的CRDTs算法
3. **性能优化** - 支持大规模会话同步
4. **通知系统** - 添加邮件/短信通知

## 故障排除

### 常见问题
1. **守护进程不启动**
   - 检查Python3是否安装
   - 检查OpenClaw网关是否运行
   - 查看日志文件: `/tmp/memory_sync_real.log`

2. **Web监控无法访问**
   - 检查端口26710是否被占用
   - 检查防火墙设置
   - 查看日志文件: `/tmp/web_monitor_demo.log`

3. **记忆文件不更新**
   - 检查文件权限
   - 检查守护进程是否运行
   - 查看同步日志

### 日志文件
- **守护进程日志**: `/tmp/memory_sync_real.log`
- **Web监控日志**: `/tmp/web_monitor_demo.log`
- **启动脚本日志**: `~/.openclaw/workspace/sync_logs/`

## 版本历史
- **v1.0** (2026-04-09) - 初始版本发布
  - Python守护进程实现
  - Web监控界面
  - 完整的启动管理系统
  - 模拟消息发送功能

## 许可证
本项目基于OpenClaw技能框架开发，遵循相关开源协议。

## 支持与反馈
如有问题或建议，请通过OpenClaw社区反馈。