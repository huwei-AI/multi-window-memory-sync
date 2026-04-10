#!/usr/bin/env python3
"""
记忆同步系统Web监控界面
端口: 26710
"""

import json
import os
import time
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading

# 配置
MEMORY_FILE = os.path.expanduser("~/.openclaw/workspace/MEMORY.md")
STATE_FILE = os.path.expanduser("~/.openclaw/workspace/.sync_state_complete.json")
LOG_FILE = os.path.expanduser("~/.openclaw/workspace/memory_sync_complete.log")
BACKUP_DIR = os.path.expanduser("~/.openclaw/workspace/memory_backups/complete")
PORT = 26710

class MemorySyncHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(self.generate_dashboard().encode('utf-8'))
        elif self.path == '/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(self.get_status_json().encode('utf-8'))
        elif self.path == '/memory':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain; charset=utf-8')
            self.end_headers()
            self.wfile.write(self.get_memory_content().encode('utf-8'))
        elif self.path == '/logs':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain; charset=utf-8')
            self.end_headers()
            self.wfile.write(self.get_logs().encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'404 Not Found')
    
    def log_message(self, format, *args):
        # 禁用默认日志
        pass
    
    def get_status_json(self):
        """获取系统状态JSON"""
        status = {
            "timestamp": datetime.now().isoformat(),
            "system": "记忆同步系统",
            "version": "完整集成版",
            "port": PORT
        }
        
        # 读取状态文件
        if os.path.exists(STATE_FILE):
            try:
                with open(STATE_FILE, 'r') as f:
                    state_data = json.load(f)
                status.update(state_data)
            except:
                status["state_error"] = "无法读取状态文件"
        
        # 检查文件状态
        status["files"] = {
            "memory_file": os.path.exists(MEMORY_FILE),
            "state_file": os.path.exists(STATE_FILE),
            "log_file": os.path.exists(LOG_FILE),
            "backup_dir": os.path.exists(BACKUP_DIR)
        }
        
        # 获取备份文件数量
        if os.path.exists(BACKUP_DIR):
            backups = [f for f in os.listdir(BACKUP_DIR) if f.startswith('memory_')]
            status["backup_count"] = len(backups)
        else:
            status["backup_count"] = 0
        
        return json.dumps(status, indent=2, ensure_ascii=False)
    
    def get_memory_content(self):
        """获取记忆文件内容"""
        if os.path.exists(MEMORY_FILE):
            try:
                with open(MEMORY_FILE, 'r', encoding='utf-8') as f:
                    return f.read()
            except:
                return "无法读取记忆文件"
        else:
            return "记忆文件不存在"
    
    def get_logs(self):
        """获取日志内容"""
        if os.path.exists(LOG_FILE):
            try:
                with open(LOG_FILE, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    return ''.join(lines[-100:])  # 返回最后100行
            except:
                return "无法读取日志文件"
        else:
            return "日志文件不存在"
    
    def generate_dashboard(self):
        """生成监控面板HTML"""
        status = json.loads(self.get_status_json())
        
        html = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>记忆同步系统监控</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #333; }}
        .container {{ max-width: 1200px; margin: 0 auto; padding: 20px; }}
        header {{ background: rgba(255, 255, 255, 0.9); padding: 30px; border-radius: 15px; 
                 margin-bottom: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }}
        h1 {{ color: #4a5568; margin-bottom: 10px; }}
        .subtitle {{ color: #718096; font-size: 1.1em; }}
        .status-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); 
                       gap: 20px; margin-bottom: 20px; }}
        .card {{ background: rgba(255, 255, 255, 0.9); padding: 25px; border-radius: 15px; 
                box-shadow: 0 5px 15px rgba(0,0,0,0.1); }}
        .card h2 {{ color: #4a5568; margin-bottom: 15px; font-size: 1.3em; }}
        .stat-item {{ display: flex; justify-content: space-between; padding: 10px 0; 
                     border-bottom: 1px solid #e2e8f0; }}
        .stat-label {{ color: #718096; }}
        .stat-value {{ font-weight: 600; color: #2d3748; }}
        .success {{ color: #38a169 !important; }}
        .warning {{ color: #d69e2e !important; }}
        .error {{ color: #e53e3e !important; }}
        .info {{ color: #3182ce !important; }}
        .file-status {{ display: inline-block; padding: 4px 12px; border-radius: 20px; 
                       font-size: 0.9em; margin-left: 10px; }}
        .file-ok {{ background: #c6f6d5; color: #22543d; }}
        .file-missing {{ background: #fed7d7; color: #742a2a; }}
        .actions {{ display: flex; gap: 10px; margin-top: 20px; }}
        .btn {{ padding: 10px 20px; border: none; border-radius: 8px; cursor: pointer; 
               font-weight: 600; transition: all 0.3s; text-decoration: none; display: inline-block; }}
        .btn-primary {{ background: #4299e1; color: white; }}
        .btn-primary:hover {{ background: #3182ce; }}
        .btn-secondary {{ background: #e2e8f0; color: #4a5568; }}
        .btn-secondary:hover {{ background: #cbd5e0; }}
        .log-panel {{ background: #1a202c; color: #cbd5e0; padding: 20px; border-radius: 10px; 
                    font-family: 'Monaco', 'Menlo', monospace; font-size: 0.9em; 
                    max-height: 400px; overflow-y: auto; }}
        .log-entry {{ margin-bottom: 5px; }}
        .log-time {{ color: #81e6d9; }}
        .log-info {{ color: #68d391; }}
        .log-warn {{ color: #f6e05e; }}
        .log-error {{ color: #fc8181; }}
        footer {{ text-align: center; margin-top: 30px; color: rgba(255,255,255,0.7); 
                font-size: 0.9em; }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔄 记忆同步系统监控</h1>
            <p class="subtitle">实时监控多窗口记忆同步状态 - 端口 {PORT}</p>
            <p class="subtitle">最后更新: {status.get('timestamp', '未知')}</p>
        </header>
        
        <div class="status-grid">
            <div class="card">
                <h2>📊 系统状态</h2>
                <div class="stat-item">
                    <span class="stat-label">系统版本</span>
                    <span class="stat-value info">{status.get('version', '未知')}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">最后同步</span>
                    <span class="stat-value">{status.get('last_sync', '从未同步')}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">总同步次数</span>
                    <span class="stat-value info">{status.get('total_syncs', 0)}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">成功次数</span>
                    <span class="stat-value success">{status.get('success_count', 0)}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">失败次数</span>
                    <span class="stat-value error">{status.get('error_count', 0)}</span>
                </div>
            </div>
            
            <div class="card">
                <h2>📁 文件状态</h2>
                <div class="stat-item">
                    <span class="stat-label">记忆文件</span>
                    <span>
                        {status['files'].get('memory_file', False)}
                        <span class="file-status {'file-ok' if status['files'].get('memory_file') else 'file-missing'}">
                            {'正常' if status['files'].get('memory_file') else '缺失'}
                        </span>
                    </span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">状态文件</span>
                    <span>
                        {status['files'].get('state_file', False)}
                        <span class="file-status {'file-ok' if status['files'].get('state_file') else 'file-missing'}">
                            {'正常' if status['files'].get('state_file') else '缺失'}
                        </span>
                    </span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">日志文件</span>
                    <span>
                        {status['files'].get('log_file', False)}
                        <span class="file-status {'file-ok' if status['files'].get('log_file') else 'file-missing'}">
                            {'正常' if status['files'].get('log_file') else '缺失'}
                        </span>
                    </span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">备份目录</span>
                    <span>
                        {status['files'].get('backup_dir', False)}
                        <span class="file-status {'file-ok' if status['files'].get('backup_dir') else 'file-missing'}">
                            {'正常' if status['files'].get('backup_dir') else '缺失'}
                        </span>
                    </span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">备份文件数</span>
                    <span class="stat-value info">{status.get('backup_count', 0)}</span>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h2>📝 最近日志</h2>
            <div class="log-panel" id="logPanel">
                <!-- 日志内容将通过JavaScript加载 -->
                正在加载日志...
            </div>
            <div class="actions">
                <a href="/logs" class="btn btn-secondary" target="_blank">查看完整日志</a>
                <a href="/memory" class="btn btn-secondary" target="_blank">查看记忆文件</a>
                <a href="/status" class="btn btn-secondary" target="_blank">查看JSON状态</a>
            </div>
        </div>
        
        <footer>
            <p>记忆同步系统 &copy; 2026 - 基于OpenClaw构建</p>
            <p>服务器时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        </footer>
    </div>
    
    <script>
        // 加载日志
        async function loadLogs() {{
            try {{
                const response = await fetch('/logs');
                const logs = await response.text();
                document.getElementById('logPanel').innerHTML = formatLogs(logs);
            }} catch (error) {{
                document.getElementById('logPanel').innerHTML = '无法加载日志: ' + error;
            }}
        }}
        
        // 格式化日志
        function formatLogs(logs) {{
            const lines = logs.split('\\n');
            return lines.map(line => {{
                if (!line.trim()) return '';
                let className = 'log-entry';
                if (line.includes('[INFO]')) className += ' log-info';
                else if (line.includes('[WARN]')) className += ' log-warn';
                else if (line.includes('[ERROR]')) className += ' log-error';
                return `<div class="${{className}}">${{line}}</div>`;
            }}).join('');
        }}
        
        // 自动刷新日志
        loadLogs();
        setInterval(loadLogs, 5000);
        
        // 自动刷新页面数据
        setInterval(() => {{
            window.location.reload();
        }}, 30000); // 30秒刷新一次
    </script>
</body>
</html>"""
        return html

def start_web_server():
    """启动Web服务器"""
    server = HTTPServer(('0.0.0.0', PORT), MemorySyncHandler)
    print(f"🚀 记忆同步系统Web监控已启动")
    print(f"📊 访问地址: http://localhost:{PORT}")
    print(f"📊 外部访问: http://81.71.7.59:{PORT}")
    print(f"⏰ 启动时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("🛑 按 Ctrl+C 停止服务器")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 正在停止Web服务器...")
        server.server_close()
        print("✅ Web服务器已停止")

if __name__ == '__main__':
    start_web_server()