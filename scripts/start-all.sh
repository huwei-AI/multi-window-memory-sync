#!/bin/bash
# 启动完整的记忆同步系统

set -e

# 配置
SYNC_INTERVAL=5
WEB_PORT=26710
LOG_DIR="$HOME/.openclaw/workspace/sync_logs"
PID_DIR="/tmp/memory_sync"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 创建目录
mkdir -p "$LOG_DIR"
mkdir -p "$PID_DIR"

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# 检查进程
check_process() {
    local name="$1"
    local pid_file="$PID_DIR/$name.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0  # 进程正在运行
        else
            rm -f "$pid_file"
            return 1  # 进程不存在
        fi
    fi
    return 1  # 没有pid文件
}

# 停止进程
stop_process() {
    local name="$1"
    local pid_file="$PID_DIR/$name.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        log "${YELLOW}停止 $name (PID: $pid)...${NC}"
        kill "$pid" 2>/dev/null && sleep 1
        kill -9 "$pid" 2>/dev/null 2>/dev/null || true
        rm -f "$pid_file"
        log "${GREEN}$name 已停止${NC}"
    else
        log "${YELLOW}$name 未运行${NC}"
    fi
}

# 启动同步守护进程
start_sync_daemon() {
    log "${GREEN}启动记忆同步守护进程...${NC}"
    
    # 停止已存在的进程
    stop_process "sync_daemon"
    
    # 启动新进程
    cd "$HOME/.openclaw/skills/multi-window-memory-sync"
    SYNC_INTERVAL="$SYNC_INTERVAL" ./scripts/sync-complete.sh daemon > "$LOG_DIR/sync_daemon.log" 2>&1 &
    local pid=$!
    
    echo "$pid" > "$PID_DIR/sync_daemon.pid"
    log "${GREEN}同步守护进程已启动 (PID: $pid, 间隔: ${SYNC_INTERVAL}秒)${NC}"
    log "${BLUE}日志: $LOG_DIR/sync_daemon.log${NC}"
    
    # 等待进程启动
    sleep 3
    if check_process "sync_daemon"; then
        # 额外检查进程是否真的在运行（不是僵尸进程）
        local process_state=$(ps -o stat= -p $pid 2>/dev/null || echo "")
        if [[ "$process_state" == *"S"* ]] || [[ "$process_state" == *"R"* ]]; then
            log "${GREEN}同步守护进程启动成功${NC}"
            return 0
        else
            log "${YELLOW}同步守护进程状态异常: $process_state${NC}"
            return 1
        fi
    else
        log "${RED}同步守护进程启动失败${NC}"
        # 检查日志中的错误
        tail -5 "$LOG_DIR/sync_daemon.log" 2>/dev/null | grep -E "(ERROR|WARN|fail|error)" || true
        return 1
    fi
}

# 启动Web监控
start_web_monitor() {
    log "${GREEN}启动Web监控界面...${NC}"
    
    # 停止已存在的进程
    stop_process "web_monitor"
    
    # 检查端口是否被占用
    if netstat -tlnp 2>/dev/null | grep ":$WEB_PORT " > /dev/null; then
        log "${YELLOW}端口 $WEB_PORT 已被占用，尝试停止占用进程...${NC}"
        local port_pid=$(netstat -tlnp 2>/dev/null | grep ":$WEB_PORT " | awk '{print $7}' | cut -d'/' -f1)
        [ -n "$port_pid" ] && kill -9 "$port_pid" 2>/dev/null || true
        sleep 1
    fi
    
    # 启动Web服务器
    cd "$HOME/.openclaw/skills/multi-window-memory-sync"
    python3 ./scripts/web-monitor.py > "$LOG_DIR/web_monitor.log" 2>&1 &
    local pid=$!
    
    echo "$pid" > "$PID_DIR/web_monitor.pid"
    log "${GREEN}Web监控已启动 (PID: $pid, 端口: $WEB_PORT)${NC}"
    log "${BLUE}访问地址: http://localhost:$WEB_PORT${NC}"
    log "${BLUE}外部访问: http://81.71.7.59:$WEB_PORT${NC}"
    log "${BLUE}日志: $LOG_DIR/web_monitor.log${NC}"
    
    # 等待Web服务器启动
    sleep 3
    if curl -s http://localhost:$WEB_PORT > /dev/null 2>&1; then
        log "${GREEN}Web监控界面可正常访问${NC}"
        return 0
    else
        log "${YELLOW}Web监控启动中，可能需要更多时间...${NC}"
        sleep 2
        if curl -s http://localhost:$WEB_PORT > /dev/null 2>&1; then
            log "${GREEN}Web监控界面现在可访问${NC}"
            return 0
        else
            log "${RED}Web监控启动失败${NC}"
            return 1
        fi
    fi
}

# 显示状态
show_status() {
    echo -e "${BLUE}=== 记忆同步系统状态 ===${NC}"
    echo ""
    
    # 检查同步守护进程
    if check_process "sync_daemon"; then
        local sync_pid=$(cat "$PID_DIR/sync_daemon.pid" 2>/dev/null)
        echo -e "${GREEN}✓ 同步守护进程: 运行中 (PID: $sync_pid)${NC}"
        echo "  日志: $LOG_DIR/sync_daemon.log"
        echo "  间隔: ${SYNC_INTERVAL}秒"
    else
        echo -e "${RED}✗ 同步守护进程: 未运行${NC}"
    fi
    
    echo ""
    
    # 检查Web监控
    if check_process "web_monitor"; then
        local web_pid=$(cat "$PID_DIR/web_monitor.pid" 2>/dev/null)
        echo -e "${GREEN}✓ Web监控: 运行中 (PID: $web_pid)${NC}"
        echo "  端口: $WEB_PORT"
        echo "  访问: http://localhost:$WEB_PORT"
        echo "  日志: $LOG_DIR/web_monitor.log"
        
        # 测试Web访问
        if curl -s http://localhost:$WEB_PORT > /dev/null 2>&1; then
            echo -e "  状态: ${GREEN}可访问${NC}"
        else
            echo -e "  状态: ${YELLOW}启动中...${NC}"
        fi
    else
        echo -e "${RED}✗ Web监控: 未运行${NC}"
    fi
    
    echo ""
    
    # 显示系统信息
    echo -e "${BLUE}系统信息:${NC}"
    echo "  服务器: 81.71.7.59"
    echo "  工作目录: $HOME/.openclaw/skills/multi-window-memory-sync"
    echo "  配置目录: $LOG_DIR"
    echo "  PID目录: $PID_DIR"
    
    # 显示最近日志
    echo ""
    echo -e "${BLUE}最近同步日志:${NC}"
    tail -5 "$LOG_DIR/sync_daemon.log" 2>/dev/null || echo "  无日志"
}

# 停止所有服务
stop_all() {
    log "${YELLOW}正在停止所有服务...${NC}"
    stop_process "web_monitor"
    stop_process "sync_daemon"
    log "${GREEN}所有服务已停止${NC}"
}

# 重启所有服务
restart_all() {
    log "${YELLOW}正在重启所有服务...${NC}"
    stop_all
    sleep 2
    start_sync_daemon
    sleep 2
    start_web_monitor
    show_status
}

# 清理
cleanup() {
    log "${YELLOW}正在清理...${NC}"
    
    # 清理旧日志（保留7天）
    find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    # 清理临时文件
    rm -f "$PID_DIR"/*.pid 2>/dev/null || true
    
    log "${GREEN}清理完成${NC}"
}

# 主程序
main() {
    case "${1:-start}" in
        "start")
            start_sync_daemon
            sleep 2
            start_web_monitor
            sleep 2
            show_status
            ;;
        "stop")
            stop_all
            ;;
        "restart")
            restart_all
            ;;
        "status")
            show_status
            ;;
        "sync-only")
            start_sync_daemon
            show_status
            ;;
        "web-only")
            start_web_monitor
            show_status
            ;;
        "cleanup")
            cleanup
            ;;
        "test")
            echo -e "${GREEN}测试模式${NC}"
            echo "同步间隔: $SYNC_INTERVAL"
            echo "Web端口: $WEB_PORT"
            echo "日志目录: $LOG_DIR"
            ;;
        *)
            echo -e "${GREEN}用法: $0 [command]${NC}"
            echo "命令:"
            echo "  start      - 启动所有服务 (默认)"
            echo "  stop       - 停止所有服务"
            echo "  restart    - 重启所有服务"
            echo "  status     - 显示状态"
            echo "  sync-only  - 只启动同步守护进程"
            echo "  web-only   - 只启动Web监控"
            echo "  cleanup    - 清理旧文件"
            echo "  test       - 测试配置"
            echo ""
            echo "配置:"
            echo "  同步间隔: ${SYNC_INTERVAL}秒"
            echo "  Web端口: $WEB_PORT"
            echo "  服务器IP: 81.71.7.59"
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"