#!/bin/bash
# 增强版多窗口记忆同步系统

set -e

CONFIG_FILE="$HOME/.openclaw/skills/multi-window-memory-sync/config/sync-config.json"
MEMORY_FILE="$HOME/.openclaw/workspace/MEMORY.md"
BACKUP_DIR="$HOME/.openclaw/workspace/memory_backups"
LOG_FILE="$HOME/.openclaw/workspace/memory_sync.log"
STATE_FILE="$HOME/.openclaw/workspace/.sync_state.json"

# 读取配置
read_config() {
    if [ -f "$CONFIG_FILE" ]; then
        SYNC_INTERVAL=$(jq -r '.config.sync_interval_seconds // 5' "$CONFIG_FILE")
        MAX_SESSIONS=$(jq -r '.config.max_sessions // 10' "$CONFIG_FILE")
        ENABLED=$(jq -r '.config.enabled // true' "$CONFIG_FILE")
    else
        SYNC_INTERVAL=5
        MAX_SESSIONS=10
        ENABLED=true
    fi
}

# 初始化
init() {
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$STATE_FILE")"
    
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"last_sync": null, "session_count": 0, "error_count": 0}' > "$STATE_FILE"
    fi
    
    if [ ! -f "$MEMORY_FILE" ]; then
        echo "# 记忆同步系统初始化 $(date)" > "$MEMORY_FILE"
    fi
}

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [ "$level" = "ERROR" ] || [ "$level" = "WARN" ]; then
        echo "[$level] $message"
    fi
}

# 备份记忆文件
backup_memory() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/memory_$timestamp.md"
    
    if [ -f "$MEMORY_FILE" ]; then
        cp "$MEMORY_FILE" "$backup_file"
        log "INFO" "记忆备份到: $backup_file"
        
        # 清理旧备份（保留最近7天）
        find "$BACKUP_DIR" -name "memory_*.md" -mtime +7 -delete 2>/dev/null || true
    fi
}

# 获取活跃会话列表（模拟函数，实际应该调用OpenClaw API）
get_active_sessions() {
    # 这里应该调用 OpenClaw API 获取活跃会话
    # 暂时返回模拟数据
    echo "yuanbao:direct:session1"
    echo "yuanbao:group:胡伟的派"
    echo "yuanbao:direct:session2"
}

# 同步记忆到指定会话
sync_to_session() {
    local session="$1"
    
    log "INFO" "同步到会话: $session"
    
    # 这里应该实现实际的同步逻辑
    # 例如：通过 sessions_send 工具发送记忆更新
    # 或者通过 OpenClaw API 推送
    
    # 模拟同步成功
    return 0
}

# 主同步函数
perform_sync() {
    log "INFO" "开始记忆同步周期"
    
    # 备份当前记忆
    backup_memory
    
    # 获取活跃会话
    local sessions=()
    while IFS= read -r session; do
        sessions+=("$session")
    done < <(get_active_sessions)
    
    local session_count=${#sessions[@]}
    log "INFO" "发现 $session_count 个活跃会话"
    
    # 同步到每个会话
    local success_count=0
    for session in "${sessions[@]}"; do
        if sync_to_session "$session"; then
            ((success_count++))
        else
            log "ERROR" "同步到会话 $session 失败"
        fi
        
        # 限制最大会话数
        if [ $success_count -ge $MAX_SESSIONS ]; then
            log "WARN" "达到最大会话数限制 ($MAX_SESSIONS)"
            break
        fi
    done
    
    # 更新状态文件
    local now=$(date -Iseconds)
    echo "{\"last_sync\": \"$now\", \"session_count\": $success_count, \"error_count\": $((session_count - success_count))}" > "$STATE_FILE"
    
    log "INFO" "同步完成: $success_count/$session_count 成功"
}

# 显示状态
show_status() {
    if [ -f "$STATE_FILE" ]; then
        echo "=== 记忆同步系统状态 ==="
        echo "配置间隔: ${SYNC_INTERVAL}秒"
        echo "启用状态: ${ENABLED}"
        echo "记忆文件: $MEMORY_FILE"
        echo "日志文件: $LOG_FILE"
        echo ""
        cat "$STATE_FILE" | jq .
    else
        echo "状态文件不存在，系统可能未初始化"
    fi
}

# 主函数
main() {
    read_config
    
    if [ "$ENABLED" != "true" ]; then
        log "WARN" "记忆同步系统已禁用"
        exit 0
    fi
    
    init
    
    # 检查命令行参数
    case "${1:-}" in
        "status")
            show_status
            exit 0
            ;;
        "sync-now")
            perform_sync
            exit 0
            ;;
        "backup")
            backup_memory
            exit 0
            ;;
        "help")
            echo "用法: $0 [command]"
            echo "命令:"
            echo "  status    显示系统状态"
            echo "  sync-now  立即执行一次同步"
            echo "  backup    仅备份记忆文件"
            echo "  help      显示帮助"
            echo "  (无参数)  启动守护进程，每${SYNC_INTERVAL}秒同步一次"
            exit 0
            ;;
    esac
    
    # 守护进程模式
    log "INFO" "启动记忆同步守护进程 (同步间隔: ${SYNC_INTERVAL}秒)"
    log "INFO" "按 Ctrl+C 停止"
    
    trap 'log "INFO" "收到停止信号，退出"; exit 0' INT TERM
    
    while true; do
        perform_sync
        sleep "$SYNC_INTERVAL"
    done
}

# 运行主函数
main "$@"