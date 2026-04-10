#!/bin/bash
# 简化版记忆同步系统 - 每5秒同步一次

SYNC_INTERVAL=5
MEMORY_FILE="$HOME/.openclaw/workspace/MEMORY.md"
LOG_FILE="$HOME/.openclaw/workspace/memory_sync.log"
LAST_SYNC_FILE="$HOME/.openclaw/workspace/.last_sync"

# 初始化
init() {
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$(dirname "$LAST_SYNC_FILE")"
    
    if [ ! -f "$MEMORY_FILE" ]; then
        echo "# 记忆同步系统初始化 $(date '+%Y-%m-%d %H:%M:%S')" > "$MEMORY_FILE"
        echo "## 系统状态" >> "$MEMORY_FILE"
        echo "- 同步系统启动时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$MEMORY_FILE"
        echo "- 同步间隔: ${SYNC_INTERVAL}秒" >> "$MEMORY_FILE"
    fi
}

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 获取当前活跃会话（模拟）
get_sessions() {
    # 模拟返回会话列表
    # 实际应该调用: sessions_list 工具或 OpenClaw API
    echo "session:yuanbao:direct:当前私聊"
    echo "session:yuanbao:group:胡伟的派"
    echo "session:yuanbao:direct:其他对话"
}

# 模拟同步到会话
sync_to_session() {
    local session="$1"
    local session_type=$(echo "$session" | cut -d: -f2)
    local session_name=$(echo "$session" | cut -d: -f4)
    
    log "正在同步到: $session_name ($session_type)"
    
    # 这里应该是实际的同步逻辑
    # 例如：使用 sessions_send 工具发送记忆更新
    
    # 模拟同步延迟
    sleep 0.1
    
    return 0
}

# 更新记忆文件中的同步状态
update_memory_status() {
    local temp_file="${MEMORY_FILE}.tmp"
    
    # 创建或更新状态部分
    if grep -q "## 系统状态" "$MEMORY_FILE"; then
        # 更新现有状态
        head -n 5 "$MEMORY_FILE" > "$temp_file"
        echo "- 最后同步时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$temp_file"
        echo "- 同步会话数: $1" >> "$temp_file"
        tail -n +6 "$MEMORY_FILE" >> "$temp_file"
    else
        # 添加状态部分
        cp "$MEMORY_FILE" "$temp_file"
        echo "" >> "$temp_file"
        echo "## 系统状态" >> "$temp_file"
        echo "- 最后同步时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$temp_file"
        echo "- 同步会话数: $1" >> "$temp_file"
    fi
    
    mv "$temp_file" "$MEMORY_FILE"
}

# 主同步函数
perform_sync() {
    log "开始记忆同步..."
    
    # 获取会话列表
    local sessions=()
    while IFS= read -r session; do
        sessions+=("$session")
    done < <(get_sessions)
    
    local session_count=${#sessions[@]}
    log "发现 $session_count 个活跃会话"
    
    # 同步到每个会话
    local success_count=0
    for session in "${sessions[@]}"; do
        if sync_to_session "$session"; then
            ((success_count++))
        else
            log "同步失败: $session"
        fi
    done
    
    # 更新记忆文件状态
    update_memory_status "$success_count"
    
    # 记录最后同步时间
    date '+%Y-%m-%d %H:%M:%S' > "$LAST_SYNC_FILE"
    
    log "同步完成: $success_count/$session_count 成功"
    echo "$success_count"  # 返回成功计数
}

# 显示状态
show_status() {
    echo "=== 记忆同步系统状态 ==="
    echo "同步间隔: ${SYNC_INTERVAL}秒"
    echo "记忆文件: $MEMORY_FILE"
    echo "日志文件: $LOG_FILE"
    echo "文件大小: $(stat -c%s "$MEMORY_FILE" 2>/dev/null || echo "0") 字节"
    
    if [ -f "$LAST_SYNC_FILE" ]; then
        echo "最后同步: $(cat "$LAST_SYNC_FILE")"
    else
        echo "最后同步: 从未同步"
    fi
    
    echo ""
    echo "最近日志:"
    tail -5 "$LOG_FILE" 2>/dev/null || echo "无日志"
}

# 主函数
main() {
    init
    
    case "${1:-}" in
        "status")
            show_status
            exit 0
            ;;
        "sync-now")
            perform_sync
            exit 0
            ;;
        "help")
            echo "用法: $0 [command]"
            echo "命令:"
            echo "  status    显示系统状态"
            echo "  sync-now  立即执行一次同步"
            echo "  help      显示帮助"
            echo "  (无参数)  启动守护进程，每${SYNC_INTERVAL}秒同步一次"
            exit 0
            ;;
    esac
    
    # 守护进程模式
    log "启动记忆同步守护进程 (间隔: ${SYNC_INTERVAL}秒)"
    log "记忆文件: $MEMORY_FILE"
    
    trap 'log "收到停止信号，退出"; exit 0' INT TERM
    
    while true; do
        perform_sync > /dev/null  # 静默执行，避免输出干扰
        sleep "$SYNC_INTERVAL"
    done
}

# 运行主函数
main "$@"