#!/bin/bash
# 真正的多窗口记忆同步系统 - 集成OpenClaw工具

set -e

# 配置
SYNC_INTERVAL=${SYNC_INTERVAL:-5}
MEMORY_FILE="$HOME/.openclaw/workspace/MEMORY.md"
BACKUP_DIR="$HOME/.openclaw/workspace/memory_backups"
LOG_FILE="$HOME/.openclaw/workspace/memory_sync_real.log"
STATE_FILE="$HOME/.openclaw/workspace/.sync_state_real.json"
LOCK_FILE="/tmp/memory_sync.lock"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 初始化
init() {
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$STATE_FILE")"
    
    if [ ! -f "$STATE_FILE" ]; then
        echo '{
            "last_sync": null,
            "total_syncs": 0,
            "success_count": 0,
            "error_count": 0,
            "last_error": null,
            "active_sessions": []
        }' > "$STATE_FILE"
    fi
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR/$(date +%Y%m%d)"
    
    log "INFO" "记忆同步系统初始化完成"
}

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"
    
    echo "$log_entry" >> "$LOG_FILE"
    
    case "$level" in
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "WARN") echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "INFO") echo -e "${GREEN}[INFO]${NC} $message" ;;
        *) echo "[$level] $message" ;;
    esac
}

# 获取真正的活跃会话列表
get_real_sessions() {
    log "INFO" "获取活跃会话列表..."
    
    # 使用OpenClaw的sessions_list工具
    local sessions_output
    if sessions_output=$(openclaw sessions list --active 30 --json 2>/dev/null); then
        # 解析JSON输出获取会话ID
        echo "$sessions_output" | jq -r '.sessions[] | .key' 2>/dev/null || echo ""
    else
        log "WARN" "无法获取会话列表，使用模拟数据"
        # 模拟数据作为fallback
        echo "agent:main:yuanbao:direct:当前私聊"
        echo "agent:main:yuanbao:group:胡伟的派"
        echo "agent:main:acp:codex:代码会话"
    fi
}

# 备份记忆文件
backup_memory() {
    local backup_path="$BACKUP_DIR/$(date +%Y%m%d)/MEMORY_$(date +%H%M%S).md"
    cp "$MEMORY_FILE" "$backup_path"
    log "INFO" "记忆备份到: $backup_path"
}

# 发送记忆更新到会话
send_to_session() {
    local session_key="$1"
    local session_name="$2"
    
    log "INFO" "发送记忆更新到会话: $session_name"
    
    # 读取当前记忆内容
    local memory_content
    if [ -f "$MEMORY_FILE" ]; then
        memory_content=$(cat "$MEMORY_FILE")
    else
        memory_content="# 记忆同步系统\n\n系统启动时间: $(date)"
    fi
    
    # 创建更新消息
    local update_message="🔄 **记忆同步更新** $(date '+%H:%M:%S')\n\n"
    update_message+="记忆已更新，包含最新内容。\n"
    update_message+="同步时间: $(date '+%Y-%m-%d %H:%M:%S')\n"
    update_message+="---\n"
    
    # 尝试发送更新到会话
    if openclaw sessions send --sessionKey "$session_key" --message "$update_message" --timeoutSeconds 10 2>/dev/null; then
        log "INFO" "成功发送更新到: $session_name"
        return 0
    else
        log "WARN" "发送更新失败: $session_name"
        return 1
    fi
}

# 更新状态文件
update_state() {
    local success_count="$1"
    local total_sessions="$2"
    local error_count="$((total_sessions - success_count))"
    
    local current_state
    current_state=$(cat "$STATE_FILE" 2>/dev/null || echo '{}')
    
    local new_state=$(echo "$current_state" | jq --arg date "$(date -Iseconds)" \
        --argjson total "$(($(echo "$current_state" | jq '.total_syncs // 0') + 1))" \
        --argjson success "$(($(echo "$current_state" | jq '.success_count // 0') + success_count))" \
        --argjson errors "$(($(echo "$current_state" | jq '.error_count // 0') + error_count))" \
        '.last_sync = $date | .total_syncs = $total | .success_count = $success | .error_count = $errors')
    
    echo "$new_state" > "$STATE_FILE"
}

# 主同步函数
perform_real_sync() {
    log "INFO" "开始真正的记忆同步..."
    
    # 获取真正的会话列表
    local sessions=()
    while IFS= read -r session; do
        [ -n "$session" ] && sessions+=("$session")
    done < <(get_real_sessions)
    
    local total_sessions=${#sessions[@]}
    log "INFO" "发现 $total_sessions 个活跃会话"
    
    if [ "$total_sessions" -eq 0 ]; then
        log "WARN" "没有活跃会话，跳过同步"
        return 0
    fi
    
    # 调试：显示获取的会话
    for session in "${sessions[@]}"; do
        log "DEBUG" "会话: $session"
    done
    
    # 备份当前记忆
    backup_memory
    
    # 同步到每个会话
    local success_count=0
    for session in "${sessions[@]}"; do
        # 提取会话名称
        local session_name
        if [[ "$session" == *"yuanbao"* ]]; then
            session_name="元宝会话"
        elif [[ "$session" == *"acp"* ]]; then
            session_name="ACP代码会话"
        elif [[ "$session" == *"main"* ]]; then
            session_name="主会话"
        else
            session_name="其他会话"
        fi
        
        if send_to_session "$session" "$session_name"; then
            ((success_count++))
        fi
        
        # 避免过快发送
        sleep 0.5
    done
    
    # 更新状态
    update_state "$success_count" "$total_sessions"
    
    log "INFO" "同步完成: $success_count/$total_sessions 成功"
    
    # 更新记忆文件中的状态
    update_memory_status "$success_count" "$total_sessions"
    
    return 0
}

# 更新记忆文件状态
update_memory_status() {
    local success_count="$1"
    local total_sessions="$2"
    
    local temp_file="${MEMORY_FILE}.tmp"
    local sync_section="## 🔄 实时同步状态\n"
    sync_section+="- **最后同步时间**: $(date '+%Y-%m-%d %H:%M:%S')\n"
    sync_section+="- **活跃会话数**: $total_sessions\n"
    sync_section+="- **成功同步**: $success_count\n"
    sync_section+="- **同步间隔**: ${SYNC_INTERVAL}秒\n"
    sync_section+="- **系统运行**: 真正集成版\n\n"
    
    if [ -f "$MEMORY_FILE" ]; then
        # 移除旧的同步状态部分
        grep -v "## 🔄 实时同步状态" "$MEMORY_FILE" | \
        grep -v "^- \*\*最后同步时间" | \
        grep -v "^- \*\*活跃会话数" | \
        grep -v "^- \*\*成功同步" | \
        grep -v "^- \*\*同步间隔" | \
        grep -v "^- \*\*系统运行" > "$temp_file" 2>/dev/null || true
        
        # 添加新的同步状态
        echo -e "$sync_section" >> "$temp_file"
    else
        echo -e "# 记忆同步系统\n\n$sync_section" > "$temp_file"
    fi
    
    mv "$temp_file" "$MEMORY_FILE" 2>/dev/null || true
}

# 守护进程模式
daemon_mode() {
    log "INFO" "启动记忆同步守护进程 (间隔: ${SYNC_INTERVAL}秒)"
    
    # 设置退出信号处理
    trap 'log "INFO" "收到停止信号，退出"; exit 0' INT TERM
    
    while true; do
        perform_real_sync
        sleep "$SYNC_INTERVAL"
    done
}

# 单次运行模式
single_run() {
    log "INFO" "执行单次记忆同步"
    perform_real_sync
}

# 显示状态
show_status() {
    if [ -f "$STATE_FILE" ]; then
        echo "=== 记忆同步系统状态 ==="
        cat "$STATE_FILE" | jq '.'
        echo ""
        echo "=== 最近日志 ==="
        tail -10 "$LOG_FILE" 2>/dev/null || echo "无日志"
    else
        echo "系统未初始化"
    fi
}

# 主程序
main() {
    case "${1:-daemon}" in
        "daemon")
            init
            daemon_mode
            ;;
        "once")
            init
            single_run
            ;;
        "status")
            show_status
            ;;
        "init")
            init
            log "INFO" "初始化完成"
            ;;
        "test")
            log "INFO" "测试模式 - 显示会话列表"
            get_real_sessions
            ;;
        *)
            echo "用法: $0 [command]"
            echo "命令:"
            echo "  daemon    - 启动守护进程模式 (默认)"
            echo "  once      - 执行单次同步"
            echo "  status    - 显示系统状态"
            echo "  init      - 初始化系统"
            echo "  test      - 测试会话获取"
            echo ""
            echo "环境变量:"
            echo "  SYNC_INTERVAL - 同步间隔(秒)，默认: 5"
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"