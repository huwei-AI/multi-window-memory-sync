# API 文档

## 概述
多窗口记忆同步系统提供多种API接口，包括Web API、命令行接口和Python API。

## Web API

### 基础信息
- **基础URL**: `http://localhost:26710`
- **外部访问**: `http://81.71.7.59:26710`
- **内容类型**: JSON (除非特别说明)
- **编码**: UTF-8

### 状态接口

#### 获取系统状态
```
GET /status
```

**响应示例**:
```json
{
  "timestamp": "2026-04-09T22:45:00+08:00",
  "system": "记忆同步系统",
  "version": "完整集成版",
  "port": 26710,
  "last_sync": "2026-04-09T22:45:00+08:00",
  "total_syncs": 10,
  "success_count": 8,
  "error_count": 2,
  "files": {
    "memory_file": true,
    "state_file": true,
    "log_file": true,
    "backup_dir": true
  },
  "backup_count": 5
}
```

#### 获取记忆文件内容
```
GET /memory
```
- **Content-Type**: `text/plain; charset=utf-8`
- **返回**: 完整的MEMORY.md文件内容

#### 获取系统日志
```
GET /logs
```
- **Content-Type**: `text/plain; charset=utf-8`
- **返回**: 最近100行日志内容

#### 获取监控面板
```
GET /
```
- **Content-Type**: `text/html; charset=utf-8`
- **返回**: 完整的Web监控界面

### 控制接口

#### 手动触发同步
```
POST /sync
Content-Type: application/json

{
  "force": true,
  "notify": false
}
```

**响应**:
```json
{
  "success": true,
  "message": "同步已触发",
  "timestamp": "2026-04-09T22:46:00+08:00"
}
```

#### 清理旧文件
```
POST /cleanup
Content-Type: application/json

{
  "days": 7,
  "types": ["logs", "backups"]
}
```

## 命令行接口

### 启动管理脚本

#### 完整系统管理
```bash
# 启动完整系统
./scripts/start-all.sh start

# 停止系统
./scripts/start-all.sh stop

# 重启系统
./scripts/start-all.sh restart

# 查看状态
./scripts/start-all.sh status

# 清理旧文件
./scripts/start-all.sh cleanup
```

#### 组件独立控制
```bash
# 只启动同步守护进程
./scripts/start-all.sh sync-only

# 只启动Web监控
./scripts/start-all.sh web-only

# 测试配置
./scripts/start-all.sh test
```

### Python守护进程接口

#### 启动守护进程
```bash
python3 ./scripts/real-daemon.py start
```

#### 停止守护进程
```bash
python3 ./scripts/real-daemon.py stop
```

#### 查看状态
```bash
python3 ./scripts/real-daemon.py status
```

#### 重启守护进程
```bash
python3 ./scripts/real-daemon.py restart
```

### 其他脚本接口

#### 简单同步脚本
```bash
# 执行单次同步
./scripts/sync-complete.sh once

# 启动守护进程模式
./scripts/sync-complete.sh daemon

# 显示状态
./scripts/sync-complete.sh status
```

#### 简单守护进程
```bash
# 启动简单守护进程
./scripts/sync-simple-daemon.sh start

# 停止
./scripts/sync-simple-daemon.sh stop

# 状态
./scripts/sync-simple-daemon.sh status
```

## Python API

### 直接导入使用

#### 基本用法
```python
import sys
sys.path.append('/root/.openclaw/skills/multi-window-memory-sync/scripts')

# 导入守护进程类
from real_daemon import MemorySyncDaemon

# 创建实例
daemon = MemorySyncDaemon()

# 执行单次同步
daemon.perform_sync()

# 获取会话数量
session_count = daemon.get_sessions()
```

#### 完整示例
```python
#!/usr/bin/env python3
"""
使用记忆同步系统Python API的示例
"""

import sys
sys.path.append('/root/.openclaw/skills/multi-window-memory-sync/scripts')

try:
    # 导入守护进程
    from real_daemon import MemorySyncDaemon
    
    # 创建守护进程实例
    daemon = MemorySyncDaemon()
    
    # 执行一次同步
    print("开始同步...")
    if daemon.perform_sync():
        print("同步成功")
    else:
        print("同步失败")
        
    # 获取系统信息
    daemon.log("测试日志消息")
    
except ImportError as e:
    print(f"导入错误: {e}")
except Exception as e:
    print(f"执行错误: {e}")
```

### 配置API

#### 读取配置
```python
import json

def read_config():
    """读取配置文件"""
    config_path = '/root/.openclaw/skills/multi-window-memory-sync/config/sync-config.json'
    with open(config_path, 'r') as f:
        return json.load(f)

# 使用示例
config = read_config()
sync_interval = config['config']['sync_interval_seconds']
web_port = config['config']['web_monitor_port']
```

#### 更新配置
```python
def update_config(key, value):
    """更新配置"""
    config = read_config()
    
    # 支持嵌套键，如 "config.sync_interval_seconds"
    keys = key.split('.')
    current = config
    for k in keys[:-1]:
        current = current.setdefault(k, {})
    current[keys[-1]] = value
    
    # 写回文件
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    return True

# 使用示例
update_config('config.sync_interval_seconds', 10)
```

## 环境变量API

### 配置环境变量
```bash
# 同步间隔（秒）
export SYNC_INTERVAL=10

# Web监控端口
export WEB_PORT=26711

# 日志级别
export LOG_LEVEL=DEBUG

# 启动时使用
SYNC_INTERVAL=10 WEB_PORT=26711 ./scripts/start-all.sh start
```

### 脚本中的环境变量使用
```python
import os

# 读取环境变量
sync_interval = int(os.getenv('SYNC_INTERVAL', '5'))
web_port = int(os.getenv('WEB_PORT', '26710'))
log_level = os.getenv('LOG_LEVEL', 'INFO')
```

## 文件系统API

### 记忆文件操作
```python
import os
from datetime import datetime

MEMORY_FILE = os.path.expanduser('~/.openclaw/workspace/MEMORY.md')

def read_memory_file():
    """读取记忆文件"""
    if os.path.exists(MEMORY_FILE):
        with open(MEMORY_FILE, 'r', encoding='utf-8') as f:
            return f.read()
    return ""

def update_sync_status(session_count, sync_count):
    """更新同步状态"""
    # 实现逻辑...
    pass

def add_memory_entry(title, content):
    """添加记忆条目"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    entry = f"\n## {title}\n\n{content}\n\n*添加时间: {timestamp}*\n"
    
    with open(MEMORY_FILE, 'a', encoding='utf-8') as f:
        f.write(entry)
    
    return True
```

### 状态文件操作
```python
import json
import os

STATE_FILE = os.path.expanduser('~/.openclaw/workspace/.sync_state.json')

def read_state():
    """读取状态文件"""
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}

def update_state(success_count, total_sessions):
    """更新状态"""
    state = read_state()
    
    state['last_sync'] = datetime.now().isoformat()
    state['total_syncs'] = state.get('total_syncs', 0) + 1
    state['success_count'] = state.get('success_count', 0) + success_count
    state['error_count'] = state.get('error_count', 0) + (total_sessions - success_count)
    
    with open(STATE_FILE, 'w', encoding='utf-8') as f:
        json.dump(state, f, indent=2, ensure_ascii=False)
    
    return state
```

## 扩展API

### 自定义同步处理器
```python
class CustomSyncHandler:
    """自定义同步处理器"""
    
    def __init__(self, config):
        self.config = config
    
    def before_sync(self):
        """同步前处理"""
        print("开始同步前处理...")
        return True
    
    def after_sync(self, success, session_count):
        """同步后处理"""
        print(f"同步完成: 成功={success}, 会话数={session_count}")
        return True
    
    def on_error(self, error):
        """错误处理"""
        print(f"同步错误: {error}")
        return False

# 使用示例
handler = CustomSyncHandler(config={})
daemon = MemorySyncDaemon()
daemon.custom_handler = handler
```

### 插件系统
```python
# plugins/custom_notifier.py
class CustomNotifier:
    """自定义通知插件"""
    
    def notify(self, message, level="INFO"):
        """发送通知"""
        # 实现自定义通知逻辑
        pass

# 主程序中加载插件
def load_plugins(plugin_dir):
    """加载插件"""
    plugins = []
    for file in os.listdir(plugin_dir):
        if file.endswith('.py') and file != '__init__.py':
            module_name = file[:-3]
            module = __import__(f'plugins.{module_name}', fromlist=[''])
            if hasattr(module, 'register_plugin'):
                plugin = module.register_plugin()
                plugins.append(plugin)
    return plugins
```

## 错误处理

### 异常类
```python
class MemorySyncError(Exception):
    """记忆同步基础异常"""
    pass

class ConfigError(MemorySyncError):
    """配置错误"""
    pass

class SyncError(MemorySyncError):
    """同步错误"""
    pass

class SessionError(MemorySyncError):
    """会话错误"""
    pass
```

### 错误处理示例
```python
try:
    daemon = MemorySyncDaemon()
    result = daemon.perform_sync()
    
except ConfigError as e:
    print(f"配置错误: {e}")
except SyncError as e:
    print(f"同步错误: {e}")
except SessionError as e:
    print(f"会话错误: {e}")
except Exception as e:
    print(f"未知错误: {e}")
```

## 性能监控API

### 监控指标
```python
def get_performance_metrics():
    """获取性能指标"""
    import psutil
    import time
    
    metrics = {
        'timestamp': time.time(),
        'cpu_percent': psutil.cpu_percent(),
        'memory_usage': psutil.virtual_memory().percent,
        'disk_usage': psutil.disk_usage('/').percent,
        'process_count': len(psutil.pids())
    }
    
    return metrics

def monitor_sync_performance():
    """监控同步性能"""
    start_time = time.time()
    
    # 执行同步
    success = perform_sync()
    
    end_time = time.time()
    duration = end_time - start_time
    
    return {
        'success': success,
        'duration': duration,
        'timestamp': datetime.now().isoformat()
    }
```

## 版本信息
- **API版本**: 1.0
- **兼容性**: OpenClaw 2026.4.2+
- **最后更新**: 2026-04-09