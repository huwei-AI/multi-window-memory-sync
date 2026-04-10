#!/usr/bin/env python3
"""
真正的记忆同步守护进程
使用Python实现，更稳定
"""

import os
import sys
import time
import signal
import json
import subprocess
from datetime import datetime
import threading

# 配置
SYNC_INTERVAL = 5  # 秒
PID_FILE = "/tmp/memory_sync_real.pid"
LOG_FILE = "/tmp/memory_sync_real.log"
MEMORY_FILE = os.path.expanduser("~/.openclaw/workspace/MEMORY.md")
STATE_FILE = os.path.expanduser("~/.openclaw/workspace/.sync_state_real.json")

class MemorySyncDaemon:
    def __init__(self):
        self.running = True
        self.sync_count = 0
        
        # 设置信号处理
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
        
    def signal_handler(self, signum, frame):
        self.log(f"收到信号 {signum}，准备退出")
        self.running = False
    
    def log(self, message):
        """记录日志"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] {message}"
        print(log_entry)
        
        # 写入日志文件
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(log_entry + "\n")
    
    def get_sessions(self):
        """获取OpenClaw会话"""
        try:
            # 使用subprocess获取会话
            result = subprocess.run(
                ["openclaw", "sessions", "--active", "30", "--json"],
                capture_output=True,
                text=True,
                timeout=3
            )
            
            if result.returncode == 0 and result.stdout:
                data = json.loads(result.stdout)
                sessions = data.get("sessions", [])
                return len(sessions)
            else:
                self.log(f"获取会话失败: {result.stderr}")
                return 0
        except subprocess.TimeoutExpired:
            self.log("获取会话超时")
            return 0
        except Exception as e:
            self.log(f"获取会话异常: {e}")
            return 0
    
    def update_memory_status(self, session_count):
        """更新记忆文件状态"""
        try:
            if not os.path.exists(MEMORY_FILE):
                # 创建记忆文件
                content = "# 记忆同步系统\n\n## 实时同步状态\n"
                content += f"- 最后同步: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                content += f"- 活跃会话: {session_count}\n"
                content += f"- 同步次数: {self.sync_count}\n"
                content += f"- 守护进程: Python版运行中\n"
                
                with open(MEMORY_FILE, "w", encoding="utf-8") as f:
                    f.write(content)
                return
            
            # 读取现有内容
            with open(MEMORY_FILE, "r", encoding="utf-8") as f:
                lines = f.readlines()
            
            # 更新同步状态部分
            new_lines = []
            in_sync_section = False
            
            for line in lines:
                if "## 实时同步状态" in line:
                    in_sync_section = True
                    new_lines.append(line)
                    # 添加新的状态
                    new_lines.append(f"- 最后同步: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                    new_lines.append(f"- 活跃会话: {session_count}\n")
                    new_lines.append(f"- 同步次数: {self.sync_count}\n")
                    new_lines.append(f"- 守护进程: Python版运行中\n")
                elif in_sync_section and line.startswith("- "):
                    # 跳过旧的同步状态行
                    continue
                elif in_sync_section and not line.startswith("- "):
                    in_sync_section = False
                    new_lines.append(line)
                else:
                    new_lines.append(line)
            
            # 如果没有找到同步状态部分，添加一个
            if not any("## 实时同步状态" in line for line in new_lines):
                new_lines.append("\n## 实时同步状态\n")
                new_lines.append(f"- 最后同步: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                new_lines.append(f"- 活跃会话: {session_count}\n")
                new_lines.append(f"- 同步次数: {self.sync_count}\n")
                new_lines.append(f"- 守护进程: Python版运行中\n")
            
            # 写回文件
            with open(MEMORY_FILE, "w", encoding="utf-8") as f:
                f.writelines(new_lines)
                
        except Exception as e:
            self.log(f"更新记忆文件失败: {e}")
    
    def update_state_file(self):
        """更新状态文件"""
        try:
            state = {
                "last_sync": datetime.now().isoformat(),
                "sync_count": self.sync_count,
                "daemon": "python",
                "version": "1.0"
            }
            
            with open(STATE_FILE, "w", encoding="utf-8") as f:
                json.dump(state, f, indent=2, ensure_ascii=False)
        except Exception as e:
            self.log(f"更新状态文件失败: {e}")
    
    def perform_sync(self):
        """执行一次同步"""
        self.sync_count += 1
        self.log(f"开始第 {self.sync_count} 次同步")
        
        # 获取会话
        session_count = self.get_sessions()
        self.log(f"发现 {session_count} 个活跃会话")
        
        # 更新状态
        self.update_memory_status(session_count)
        self.update_state_file()
        
        self.log(f"第 {self.sync_count} 次同步完成")
        return True
    
    def run(self):
        """主运行循环"""
        self.log("=== Python记忆同步守护进程启动 ===")
        self.log(f"同步间隔: {SYNC_INTERVAL}秒")
        self.log(f"记忆文件: {MEMORY_FILE}")
        self.log(f"PID文件: {PID_FILE}")
        self.log("按 Ctrl+C 停止")
        
        # 写入PID文件
        with open(PID_FILE, "w") as f:
            f.write(str(os.getpid()))
        
        try:
            while self.running:
                # 执行同步
                self.perform_sync()
                
                # 等待
                for _ in range(SYNC_INTERVAL):
                    if not self.running:
                        break
                    time.sleep(1)
                    
        except KeyboardInterrupt:
            self.log("收到键盘中断")
        except Exception as e:
            self.log(f"守护进程异常: {e}")
        finally:
            self.cleanup()
    
    def cleanup(self):
        """清理资源"""
        self.log("正在清理退出...")
        
        # 删除PID文件
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
        
        # 更新记忆文件状态
        try:
            if os.path.exists(MEMORY_FILE):
                with open(MEMORY_FILE, "r", encoding="utf-8") as f:
                    content = f.read()
                
                content = content.replace("Python版运行中", "已停止")
                
                with open(MEMORY_FILE, "w", encoding="utf-8") as f:
                    f.write(content)
        except:
            pass
        
        self.log("守护进程已停止")

def start_daemon():
    """启动守护进程"""
    daemon = MemorySyncDaemon()
    daemon.run()

def stop_daemon():
    """停止守护进程"""
    if os.path.exists(PID_FILE):
        with open(PID_FILE, "r") as f:
            pid = int(f.read().strip())
        
        print(f"停止守护进程 (PID: {pid})...")
        try:
            os.kill(pid, signal.SIGTERM)
            time.sleep(1)
            
            # 检查是否停止
            try:
                os.kill(pid, 0)
                print("进程仍在运行，发送SIGKILL...")
                os.kill(pid, signal.SIGKILL)
            except OSError:
                print("进程已停止")
            
            if os.path.exists(PID_FILE):
                os.remove(PID_FILE)
                
        except ProcessLookupError:
            print("进程不存在")
            if os.path.exists(PID_FILE):
                os.remove(PID_FILE)
    else:
        print("未找到PID文件")

def show_status():
    """显示状态"""
    print("=== Python记忆同步守护进程状态 ===")
    
    if os.path.exists(PID_FILE):
        with open(PID_FILE, "r") as f:
            pid = int(f.read().strip())
        
        try:
            os.kill(pid, 0)
            print(f"状态: 运行中 (PID: {pid})")
            
            # 显示进程信息
            try:
                result = subprocess.run(
                    ["ps", "-p", str(pid), "-o", "lstart,etime"],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    lines = result.stdout.strip().split("\n")
                    if len(lines) > 1:
                        print(f"启动时间: {lines[1].split()[0]} {lines[1].split()[1]}")
                        print(f"运行时间: {lines[1].split()[2] if len(lines[1].split()) > 2 else '未知'}")
            except:
                pass
                
        except OSError:
            print("状态: PID文件存在但进程未运行")
            os.remove(PID_FILE)
    else:
        print("状态: 未运行")
    
    print()
    
    # 显示状态文件
    if os.path.exists(STATE_FILE):
        print("系统状态:")
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            state = json.load(f)
            print(json.dumps(state, indent=2, ensure_ascii=False))
    
    print()
    
    # 显示最近日志
    if os.path.exists(LOG_FILE):
        print("最近日志:")
        with open(LOG_FILE, "r", encoding="utf-8") as f:
            lines = f.readlines()
            for line in lines[-5:]:
                print(line.strip())

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python3 real-daemon.py [command]")
        print("命令:")
        print("  start     - 启动守护进程")
        print("  stop      - 停止守护进程")
        print("  status    - 显示状态")
        print("  restart   - 重启守护进程")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "start":
        start_daemon()
    elif command == "stop":
        stop_daemon()
    elif command == "status":
        show_status()
    elif command == "restart":
        stop_daemon()
        time.sleep(2)
        print("重新启动守护进程...")
        # 在后台启动
        subprocess.Popen([sys.executable, __file__, "start"])
    else:
        print(f"未知命令: {command}")
        sys.exit(1)