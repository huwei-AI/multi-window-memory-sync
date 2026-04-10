#!/bin/bash
# 启动Python守护进程

cd "$(dirname "$0")"

case "${1:-start}" in
    "start")
        echo "启动Python记忆同步守护进程..."
        python3 ./real-daemon.py start
        ;;
    "stop")
        echo "停止Python记忆同步守护进程..."
        python3 ./real-daemon.py stop
        ;;
    "status")
        echo "Python守护进程状态:"
        python3 ./real-daemon.py status
        ;;
    "restart")
        echo "重启Python记忆同步守护进程..."
        python3 ./real-daemon.py stop
        sleep 2
        python3 ./real-daemon.py start
        ;;
    *)
        echo "用法: $0 [command]"
        echo "命令:"
        echo "  start     - 启动守护进程"
        echo "  stop      - 停止守护进程"
        echo "  status    - 显示状态"
        echo "  restart   - 重启守护进程"
        exit 1
        ;;
esac