#!/bin/bash
# 简单稳定的守护进程

SYNC_INTERVAL=5
PID_FILE="/tmp/memory_sync_simple.pid"
LOG_FILE="/tmp/memory_sync_simple.log"

# 启动守护进程
start() {
    echo "启动记忆同步守护进程 (间隔: ${SYNC_INTERVAL}秒)"
    
    # 检查是否已运行
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "守护进程已在运行 (PID: $pid)"
            return 0
        else
            rm -f "$PID_FILE"
        fi
    fi
    
    # 在后台启动守护进程
    (
        echo "$$" > "$PID_FILE"
        trap 'echo "[$(date "+%Y-%m-%d %H:%M:%S")] 收到停止信号，退出"; rm -f "$PID_FILE"; exit 0' INT TERM
        
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] 守护进程启动"
        
        local count=0
        while true; do
            ((count++))
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 执行第 $count 次同步"
            
            # 简单的同步逻辑（添加超时）
            local sessions_output
            sessions_output=$(timeout 3 openclaw sessions --active 30 --json 2>/dev/null)
            local sessions=0
            if [ $? -eq 0 ] && [ -n "$sessions_output" ]; then
                sessions=$(echo "$sessions_output" | jq -r '.sessions[] | .key' 2>/dev/null | wc -l)
            fi
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 发现 $sessions 个活跃会话"
            
            # 更新记忆文件状态
            update_memory_status $count $sessions
            
            # 等待
            sleep "$SYNC_INTERVAL"
        done
    ) >> "$LOG_FILE" 2>&1 &
    
    local daemon_pid=$!
    echo "守护进程已启动 (PID: $daemon_pid)"
    echo "日志文件: $LOG_FILE"
    
    # 等待一下确保进程启动
    sleep 2
    if kill -0 $daemon_pid 2>/dev/null; then
        echo "守护进程运行正常"
        return 0
    else
        echo "守护进程启动失败"
        return 1
    fi
}

# 更新记忆状态
update_memory_status() {
    local count=$1
    local sessions=$2
    local memory_file="$HOME/.openclaw/workspace/MEMORY.md"
    
    if [ -f "$memory_file" ]; then
        # 创建临时文件
        local temp_file="${memory_file}.tmp"
        
        # 移除旧的同步状态
        grep -v "## 简单同步状态" "$memory_file" | \
        grep -v "^- 同步次数" | \
        grep -v "^- 活跃会话" | \
        grep -v "^- 最后同步" > "$temp_file" 2>/dev/null || cat "$memory_file" > "$temp_file"
        
        # 添加新的同步状态
        echo "" >> "$temp_file"
        echo "## 简单同步状态" >> "$temp_file"
        echo "- 同步次数: $count" >> "$temp_file"
        echo "- 活跃会话: $sessions" >> "$temp_file"
        echo "- 最后同步: $(date '+%Y-%m-%d %H:%M:%S')" >> "$temp_file"
        echo "- 守护进程: 运行中" >> "$temp_file"
        
        mv "$temp_file" "$memory_file" 2>/dev/null || true
    fi
}

# 停止守护进程
stop() {
    echo "停止守护进程..."
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            sleep 1
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid"
            fi
            echo "守护进程已停止 (PID: $pid)"
        else
            echo "进程 $pid 未运行"
        fi
        rm -f "$PID_FILE"
    else
        echo "未找到PID文件"
    fi
    
    # 更新记忆文件状态
    local memory_file="$HOME/.openclaw/workspace/MEMORY.md"
    if [ -f "$memory_file" ]; then
        sed -i '/守护进程: 运行中/s/运行中/已停止/' "$memory_file" 2>/dev/null || true
    fi
}

# 显示状态
status() {
    echo "=== 简单同步守护进程状态 ==="
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "状态: 运行中 (PID: $pid)"
            echo "启动时间: $(ps -o lstart= -p $pid 2>/dev/null || echo "未知")"
        else
            echo "状态: PID文件存在但进程未运行"
            rm -f "$PID_FILE"
        fi
    else
        echo "状态: 未运行"
    fi
    
    echo ""
    echo "最近日志:"
    tail -10 "$LOG_FILE" 2>/dev/null || echo "无日志"
}

# 主程序
case "${1:-start}" in
    "start")
        start
        ;;
    "stop")
        stop
        ;;
    "status")
        status
        ;;
    "restart")
        stop
        sleep 1
        start
        ;;
    *)
        echo "用法: $0 [command]"
        echo "命令:"
        echo "  start     - 启动守护进程 (默认)"
        echo "  stop      - 停止守护进程"
        echo "  status    - 显示状态"
        echo "  restart   - 重启守护进程"
        exit 1
        ;;
esac