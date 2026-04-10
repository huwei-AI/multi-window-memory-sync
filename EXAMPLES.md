# 使用示例

## 目录
1. [基本使用](#基本使用)
2. [Web监控](#web监控)
3. [命令行操作](#命令行操作)
4. [Python集成](#python集成)
5. [高级配置](#高级配置)
6. [故障排除](#故障排除)
7. [实际场景](#实际场景)

## 基本使用

### 示例1：快速启动
```bash
# 进入技能目录
cd ~/.openclaw/skills/multi-window-memory-sync

# 启动完整系统
./scripts/start-all.sh start

# 查看状态
./scripts/start-all.sh status

# 输出示例：
# === 记忆同步系统状态 ===
# ✓ 同步守护进程: 运行中 (PID: 12345)
# ✓ Web监控: 运行中 (PID: 12346)
#   端口: 26710
#   访问: http://localhost:26710
```

### 示例2：手动添加记忆
```bash
# 手动向记忆文件添加内容
echo "" >> ~/.openclaw/workspace/MEMORY.md
echo "## 项目会议记录 $(date '+%Y-%m-%d %H:%M:%S')" >> ~/.openclaw/workspace/MEMORY.md
echo "- 主题: 记忆同步系统演示" >> ~/.openclaw/workspace/MEMORY.md
echo "- 参与者: 开发团队" >> ~/.openclaw/workspace/MEMORY.md
echo "- 结论: 系统运行正常" >> ~/.openclaw/workspace/MEMORY.md

# 等待同步（5秒后）
sleep 5

# 查看更新后的记忆文件
tail -10 ~/.openclaw/workspace/MEMORY.md
```

### 示例3：检查同步状态
```bash
# 查看实时同步状态
curl -s http://localhost:26710/status | jq '.'

# 输出示例：
# {
#   "timestamp": "2026-04-09T22:45:00+08:00",
#   "system": "记忆同步系统",
#   "version": "完整集成版",
#   "last_sync": "2026-04-09T22:45:00+08:00",
#   "total_syncs": 15,
#   "success_count": 12,
#   "error_count": 3
# }
```

## Web监控

### 示例4：访问监控面板
```bash
# 使用curl获取HTML界面
curl -s http://localhost:26710 | grep -o "<title>[^<]*</title>"

# 使用浏览器访问（如果支持）
# 打开: http://localhost:26710
# 或: http://81.71.7.59:26710
```

### 示例5：获取原始数据
```bash
# 获取记忆文件内容
curl -s http://localhost:26710/memory | head -20

# 获取系统日志
curl -s http://localhost:26710/logs | tail -10

# 获取JSON状态
curl -s http://localhost:26710/status | jq '.files'
```

### 示例6：自动化监控
```bash
#!/bin/bash
# 自动化监控脚本

MONITOR_URL="http://localhost:26710/status"

# 检查系统状态
check_system() {
    response=$(curl -s "$MONITOR_URL")
    
    if [ $? -eq 0 ]; then
        last_sync=$(echo "$response" | jq -r '.last_sync')
        total_syncs=$(echo "$response" | jq -r '.total_syncs')
        
        echo "系统状态正常"
        echo "最后同步: $last_sync"
        echo "总同步次数: $total_syncs"
        return 0
    else
        echo "系统监控不可用"
        return 1
    fi
}

# 每60秒检查一次
while true; do
    check_system
    sleep 60
done
```

## 命令行操作

### 示例7：批量操作
```bash
#!/bin/bash
# 批量操作示例

SKILL_DIR="/root/.openclaw/skills/multi-window-memory-sync"

# 启动系统
start_system() {
    echo "启动记忆同步系统..."
    cd "$SKILL_DIR"
    ./scripts/start-all.sh start
    sleep 5
}

# 执行测试同步
test_sync() {
    echo "执行测试同步..."
    # 添加测试记忆
    echo "## 测试同步 $(date '+%H:%M:%S')" >> ~/.openclaw/workspace/MEMORY.md
    echo "- 测试状态: 进行中" >> ~/.openclaw/workspace/MEMORY.md
    
    # 等待同步
    sleep 6
    
    # 验证同步
    echo "验证同步结果..."
    grep "测试同步" ~/.openclaw/workspace/MEMORY.md
}

# 停止系统
stop_system() {
    echo "停止系统..."
    cd "$SKILL_DIR"
    ./scripts/start-all.sh stop
}

# 主流程
start_system
test_sync
stop_system
```

### 示例8：定时任务
```bash
# 使用crontab定时备份记忆文件
crontab -e

# 添加以下内容：
# 每天凌晨2点备份记忆文件
0 2 * * * cp ~/.openclaw/workspace/MEMORY.md ~/.openclaw/workspace/backups/MEMORY_$(date +\%Y\%m\%d).md

# 每小时检查系统状态
0 * * * * cd /root/.openclaw/skills/multi-window-memory-sync && ./scripts/start-all.sh status >> /var/log/memory-sync-status.log
```

### 示例9：日志分析
```bash
# 分析同步日志
LOG_FILE="/tmp/memory_sync_real.log"

# 统计同步次数
echo "=== 同步统计 ==="
grep -c "开始第.*次同步" "$LOG_FILE"

# 统计成功/失败
echo "=== 成功统计 ==="
grep -c "✓" "$LOG_FILE"

echo "=== 失败统计 ==="
grep -c "✗" "$LOG_FILE"

# 提取最近错误
echo "=== 最近错误 ==="
grep -A2 -B2 "ERROR\|失败\|超时" "$LOG_FILE" | tail -20
```

## Python集成

### 示例10：Python脚本集成
```python
#!/usr/bin/env python3
"""
Python集成示例
"""

import subprocess
import json
import time
from datetime import datetime

class MemorySyncClient:
    """记忆同步客户端"""
    
    def __init__(self, skill_dir):
        self.skill_dir = skill_dir
    
    def start(self):
        """启动系统"""
        cmd = ["./scripts/start-all.sh", "start"]
        result = subprocess.run(
            cmd,
            cwd=self.skill_dir,
            capture_output=True,
            text=True
        )
        return result.returncode == 0
    
    def get_status(self):
        """获取状态"""
        try:
            import requests
            response = requests.get("http://localhost:26710/status", timeout=5)
            return response.json()
        except:
            return {"error": "无法获取状态"}
    
    def add_memory(self, title, content):
        """添加记忆"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        memory_entry = f"\n## {title}\n\n{content}\n\n*添加时间: {timestamp}*\n"
        
        with open("/root/.openclaw/workspace/MEMORY.md", "a") as f:
            f.write(memory_entry)
        
        return True

# 使用示例
if __name__ == "__main__":
    client = MemorySyncClient("/root/.openclaw/skills/multi-window-memory-sync")
    
    # 启动系统
    print("启动系统...")
    client.start()
    time.sleep(5)
    
    # 获取状态
    status = client.get_status()
    print(f"系统状态: {json.dumps(status, indent=2)}")
    
    # 添加记忆
    print("添加测试记忆...")
    client.add_memory("Python测试", "这是通过Python脚本添加的记忆内容")
    
    # 等待同步
    time.sleep(6)
    print("记忆添加完成")
```

### 示例11：自定义同步处理器
```python
#!/usr/bin/env python3
"""
自定义同步处理器示例
"""

import sys
sys.path.append('/root/.openclaw/skills/multi-window-memory-sync/scripts')

# 导入并修改守护进程
exec(open('/root/.openclaw/skills/multi-window-memory-sync/scripts/real-daemon.py').read())

class EnhancedMemorySyncDaemon(MemorySyncDaemon):
    """增强版记忆同步守护进程"""
    
    def perform_sync(self):
        """重写同步方法，添加自定义逻辑"""
        self.log("=== 增强版同步开始 ===")
        
        # 调用父类方法
        result = super().perform_sync()
        
        # 添加自定义逻辑
        self.log("执行自定义后处理...")
        self.send_notification()
        self.update_custom_metrics()
        
        return result
    
    def send_notification(self):
        """发送自定义通知"""
        self.log("发送自定义通知...")
        # 这里可以集成邮件、短信等通知方式
    
    def update_custom_metrics(self):
        """更新自定义指标"""
        self.log("更新自定义指标...")
        # 这里可以更新到监控系统

# 启动增强版守护进程
if __name__ == "__main__":
    daemon = EnhancedMemorySyncDaemon()
    daemon.run()
```

### 示例12：API客户端
```python
#!/usr/bin/env python3
"""
REST API客户端示例
"""

import requests
import json

class MemorySyncAPI:
    """记忆同步API客户端"""
    
    def __init__(self, base_url="http://localhost:26710"):
        self.base_url = base_url
    
    def get_status(self):
        """获取系统状态"""
        response = requests.get(f"{self.base_url}/status")
        return response.json()
    
    def get_memory(self):
        """获取记忆内容"""
        response = requests.get(f"{self.base_url}/memory")
        return response.text
    
    def get_logs(self):
        """获取系统日志"""
        response = requests.get(f"{self.base_url}/logs")
        return response.text
    
    def trigger_sync(self):
        """触发同步"""
        response = requests.post(
            f"{self.base_url}/sync",
            json={"force": True, "notify": False}
        )
        return response.json()
    
    def cleanup(self, days=7):
        """清理旧文件"""
        response = requests.post(
            f"{self.base_url}/cleanup",
            json={"days": days, "types": ["logs", "backups"]}
        )
        return response.json()

# 使用示例
api = MemorySyncAPI()

# 获取状态
status = api.get_status()
print(f"系统版本: {status.get('version')}")
print(f"最后同步: {status.get('last_sync')}")

# 获取记忆内容
memory = api.get_memory()
print(f"记忆文件大小: {len(memory)} 字符")

# 触发同步
result = api.trigger_sync()
print(f"同步结果: {result.get('message')}")
```

## 高级配置

### 示例13：自定义配置
```json
// custom-config.json
{
  "config": {
    "sync_interval_seconds": 3,
    "web_monitor_port": 26711,
    "enabled": true,
    "backup_enabled": true,
    "backup_retention_days": 30,
    "log_level": "DEBUG"
  },
  "notifications": {
    "on_sync_success": true,
    "on_sync_failure": true,
    "email": "admin@example.com"
  },
  "custom_rules": {
    "ignore_patterns": ["## 临时记录", "## 测试"],
    "auto_cleanup": true,
    "max_file_size_mb": 10
  }
}
```

### 示例14：环境变量配置
```bash
#!/bin/bash
# 使用环境变量配置

export SYNC_INTERVAL=2          # 2秒同步间隔
export WEB_PORT=26712           # 使用不同端口
export LOG_LEVEL=DEBUG          # 调试日志
export BACKUP_ENABLED=true      # 启用备份
export MAX_SESSIONS=20          # 最大会话数

# 启动配置后的系统
cd ~/.openclaw/skills/multi-window-memory-sync
./scripts/start-all.sh start
```

### 示例15：多实例部署
```bash
#!/bin/bash
# 部署多个实例

# 实例1 - 主要服务
INSTANCE1_DIR="/opt/memory-sync/instance1"
cp -r ~/.openclaw/skills/multi-window-memory-sync "$INSTANCE1_DIR"
cd "$INSTANCE1_DIR"
sed -i 's/26710/26711/g' config/sync-config.json
./scripts/start-all.sh start

# 实例2 - 备份服务
INSTANCE2_DIR="/opt/memory-sync/instance2"
cp -r ~/.openclaw/skills/multi-window-memory-sync "$INSTANCE2_DIR"
cd "$INSTANCE2_DIR"
sed -i 's/26710/26712/g' config/sync-config.json
sed -i 's/5/10/g' config/sync-config.json  # 10秒间隔
./scripts/start-all.sh start

# 负载均衡配置
echo "多实例部署完成："
echo "- 实例1: http://localhost:26711"
echo "- 实例2: http://localhost:26712"
```

## 故障排除

### 示例16：诊断脚本
```bash
#!/bin/bash
# 系统诊断脚本

echo "=== 记忆同步系统诊断 ==="
echo "诊断时间: $(date)"

# 1. 检查进程
echo -e "\n1. 检查进程状态:"
ps aux | grep -E "(real-daemon|web-monitor)" | grep -v grep

# 2. 检查端口
echo -e "\n2. 检查端口占用:"
netstat -tlnp | grep :26710

# 3. 检查文件
echo -e "\n3. 检查关键文件:"
ls -la ~/.openclaw/workspace/MEMORY.md 2>/dev/null || echo "记忆文件不存在"
ls -la /tmp/memory_sync_real.log 2>/dev/null || echo "日志文件不存在"

# 4. 检查Web服务
echo -e "\n4. 检查Web服务:"
curl -s http://localhost:26710 > /dev/null && echo "Web服务正常" || echo "Web服务异常"

# 5. 检查最近错误
echo -e "\n5. 最近错误日志:"
tail -20 /tmp/memory_sync_real.log 2>/dev/null | grep -E "(ERROR|WARN|失败|超时)" || echo "无错误日志"

echo -e "\n=== 诊断完成 ==="
```

### 示例17：自动恢复脚本
```bash
#!/bin/bash
# 自动恢复脚本

MAX_RETRIES=3
RETRY_DELAY=5

check_and_recover() {
    # 检查系统状态
    if curl -s http://localhost:26710/status > /dev/null 2>&1; then
        echo "系统运行正常"
        return 0
    else
        echo "系统异常，尝试恢复..."
        return 1
    fi
}

# 主恢复逻辑
for attempt in $(seq 1 $MAX_RETRIES); do
    echo "恢复尝试 $attempt/$MAX_RETRIES"
    
    if check_and_recover; then
        echo "系统恢复成功"
        exit 0
    fi
    
    # 停止可能存在的进程
    pkill -f "real-daemon.py" 2>/dev/null
    pkill -f "web-monitor.py" 2>/dev/null
    sleep 2
    
    # 重新启动
    cd ~/.openclaw/skills/multi-window-memory-sync
    ./scripts/start-all.sh start > /tmp/recovery.log 2>&1
    
    sleep $RETRY_DELAY
done

echo "恢复失败，请手动检查"
exit 1
```

## 实际场景

### 示例18：团队协作场景
```bash
#!/bin/bash
# 团队协作配置

# 设置团队共享记忆
TEAM_MEMORY="## 团队协作配置\n\n### 项目成员\n- 张三: 前端开发\n- 李四: 后端开发\n- 王五: 测试\n\n### 项目进度\n- [x] 需求分析\n- [x] 系统设计\n- [ ] 开发实现\n- [ ] 测试验收"

# 写入团队记忆
echo -e "$TEAM_MEMORY" >> ~/.openclaw/workspace/MEMORY.md

# 启动同步系统
cd ~/.openclaw/skills/multi-window-memory-sync
./scripts/start-all.sh start

echo "团队协作系统已启动"
echo "所有团队成员都可以看到最新的项目进度"
echo "监控地址: http://localhost:26710"
```

### 示例19：项目管理场景
```python
#!/usr/bin/env python3
"""
项目管理集成
"""

import json
from datetime import datetime

class ProjectManager:
    """项目管理器"""
    
    def __init__(self):
        self.memory_file = "/root/.openclaw/workspace/MEMORY.md"
    
    def add_task(self, project, task, assignee, due_date):
        """添加任务"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        task_entry = f"""
## 任务: {task