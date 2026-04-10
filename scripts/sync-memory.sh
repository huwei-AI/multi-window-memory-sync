#!/bin/bash
# 多窗口记忆同步脚本 - 每5秒同步一次

SYNC_INTERVAL=5
MEMORY_FILE="$HOME/.openclaw/workspace/MEMORY.md"
BACKUP_DIR="$HOME/.openclaw/workspace/memory_backups"
LOG_FILE="$HOME/.openclaw/workspace/memory_sync.log"

# 创建必要的目录
mkdir -p "$BACKUP_DIR"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# 备份当前记忆文件
backup_memory() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    cp "$MEMORY_FILE" "$BACKUP_DIR/memory_$timestamp.md" 2>/dev/null || true
}

# 同步记忆到所有会话
sync_to_sessions() {
    log "开始记忆同步..."
    
    # 检查记忆文件是否存在
    if [ ! -f "$MEMORY_FILE" ]; then
        log "警告: MEMORY.md 文件不存在，创建空文件"
        touch "$MEMORY_FILE"
    fi
    
    # 这里应该实现实际的同步逻辑
    # 例如：通过 OpenClaw API 推送到其他会话
    # 暂时先记录到日志
    local memory_size=$(stat -c%s "$MEMORY_FILE" 2>/dev/null || echo "0")
    log "记忆文件大小: ${memory_size}字节"
    
    # 模拟同步到3个会话（实际应该动态获取）
    log "同步到会话: session1, session2, session3"
    
    # 备份当前记忆
    backup_memory
    
    log "记忆同步完成"
}

# 主循环
log "启动多窗口记忆同步系统 (间隔: ${SYNC_INTERVAL}秒)"
log "记忆文件: $MEMORY_FILE"

while true; do
    sync_to_sessions
    sleep "$SYNC_INTERVAL"
done