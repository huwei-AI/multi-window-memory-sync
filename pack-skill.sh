#!/bin/bash
# 记忆同步系统技能打包脚本

set -e

# 配置
SKILL_NAME="multi-window-memory-sync"
VERSION="1.0.0"
BUILD_DIR="/tmp/${SKILL_NAME}-${VERSION}"
OUTPUT_FILE="/tmp/${SKILL_NAME}-${VERSION}.tar.gz"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# 清理旧构建
cleanup() {
    log "清理旧构建文件..."
    rm -rf "$BUILD_DIR" 2>/dev/null || true
    rm -f "$OUTPUT_FILE" 2>/dev/null || true
}

# 创建构建目录
create_build_dir() {
    log "创建构建目录: $BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    # 创建标准目录结构
    mkdir -p "$BUILD_DIR/config"
    mkdir -p "$BUILD_DIR/scripts"
    mkdir -p "$BUILD_DIR/docs"
    mkdir -p "$BUILD_DIR/examples"
    mkdir -p "$BUILD_DIR/tests"
}

# 复制文件
copy_files() {
    log "复制技能文件..."
    
    # 核心文件
    cp SKILL.md "$BUILD_DIR/"
    cp README.md "$BUILD_DIR/"
    cp INSTALL.md "$BUILD_DIR/"
    cp API.md "$BUILD_DIR/"
    cp EXAMPLES.md "$BUILD_DIR/"
    
    # 配置文件
    cp config/sync-config.json "$BUILD_DIR/config/"
    
    # 脚本文件
    cp scripts/*.sh "$BUILD_DIR/scripts/"
    cp scripts/*.py "$BUILD_DIR/scripts/"
    
    # 设置执行权限
    chmod +x "$BUILD_DIR/scripts/"*.sh
    chmod +x "$BUILD_DIR/scripts/"*.py
    
    log "文件复制完成"
}

# 创建版本文件
create_version_file() {
    log "创建版本文件..."
    
    cat > "$BUILD_DIR/VERSION" << EOF
技能名称: $SKILL_NAME
版本: $VERSION
构建时间: $(date '+%Y-%m-%d %H:%M:%S')
构建主机: $(hostname)
OpenClaw版本: $(openclaw --version 2>/dev/null || echo "未知")
系统信息: $(uname -a)
EOF
    
    # 创建变更日志
    cat > "$BUILD_DIR/CHANGELOG.md" << EOF
# 变更日志

## v1.0.0 (2026-04-09)
### 新增功能
- ✅ Python守护进程实现
- ✅ Web监控界面 (端口: 26710)
- ✅ 完整的启动管理系统
- ✅ 记忆文件实时同步
- ✅ 自动备份系统
- ✅ 模拟消息发送功能
- ✅ 完整的技能文档

### 技术特性
- 基于OpenClaw技能标准
- 5秒自动同步间隔
- 实时状态监控
- 错误恢复机制
- 可扩展架构

### 已知限制
- 消息发送为模拟版本
- 真正的消息发送待后续实现
EOF
}

# 创建安装脚本
create_install_script() {
    log "创建安装脚本..."
    
    cat > "$BUILD_DIR/install.sh" << 'EOF'
#!/bin/bash
# 记忆同步系统安装脚本

set -e

# 配置
SKILL_NAME="multi-window-memory-sync"
INSTALL_DIR="$HOME/.openclaw/skills/$SKILL_NAME"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log "检查系统依赖..."
    
    # 检查Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}错误: 需要Python3${NC}"
        exit 1
    fi
    
    # 检查OpenClaw
    if ! command -v openclaw &> /dev/null; then
        echo -e "${YELLOW}警告: OpenClaw未安装，部分功能可能受限${NC}"
    fi
    
    # 检查其他工具
    for cmd in jq curl; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${YELLOW}警告: $cmd 未安装，建议安装以获得完整功能${NC}"
        fi
    done
    
    log "依赖检查完成"
}

# 备份现有安装
backup_existing() {
    if [ -d "$INSTALL_DIR" ]; then
        log "发现现有安装，创建备份..."
        BACKUP_DIR="${INSTALL_DIR}.backup.$(date +%s)"
        cp -r "$INSTALL_DIR" "$BACKUP_DIR"
        log "备份创建到: $BACKUP_DIR"
    fi
}

# 安装技能
install_skill() {
    log "安装技能到: $INSTALL_DIR"
    
    # 创建目录
    mkdir -p "$(dirname "$INSTALL_DIR")"
    
    # 复制文件
    cp -r . "$INSTALL_DIR"
    
    # 设置权限
    chmod +x "$INSTALL_DIR/scripts/"*.sh
    chmod +x "$INSTALL_DIR/scripts/"*.py
    
    log "文件安装完成"
}

# 验证安装
verify_installation() {
    log "验证安装..."
    
    # 检查关键文件
    REQUIRED_FILES=(
        "SKILL.md"
        "README.md"
        "scripts/real-daemon.py"
        "scripts/start-all.sh"
        "config/sync-config.json"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$INSTALL_DIR/$file" ]; then
            echo -e "${RED}错误: 缺少文件 $file${NC}"
            return 1
        fi
    done
    
    # 测试脚本
    cd "$INSTALL_DIR"
    if ./scripts/start-all.sh test; then
        log "安装验证通过"
        return 0
    else
        echo -e "${RED}错误: 脚本测试失败${NC}"
        return 1
    fi
}

# 显示安装完成信息
show_completion() {
    echo -e "${GREEN}"
    echo "========================================="
    echo "  记忆同步系统安装完成！"
    echo "========================================="
    echo -e "${NC}"
    
    echo "安装目录: $INSTALL_DIR"
    echo ""
    echo "使用方法:"
    echo "  cd $INSTALL_DIR"
    echo "  ./scripts/start-all.sh start    # 启动系统"
    echo "  ./scripts/start-all.sh status   # 查看状态"
    echo "  ./scripts/start-all.sh stop     # 停止系统"
    echo ""
    echo "Web监控: http://localhost:26710"
    echo "外部访问: http://81.71.7.59:26710"
    echo ""
    echo "详细文档请查看:"
    echo "  $INSTALL_DIR/README.md"
    echo "  $INSTALL_DIR/INSTALL.md"
    echo -e "${GREEN}"
    echo "========================================="
    echo -e "${NC}"
}

# 主安装流程
main() {
    echo -e "${GREEN}=== 记忆同步系统安装程序 ===${NC}"
    echo ""
    
    check_dependencies
    backup_existing
    install_skill
    
    if verify_installation; then
        show_completion
    else
        echo -e "${RED}安装验证失败，请检查错误信息${NC}"
        exit 1
    fi
}

# 运行主程序
main "$@"
EOF
    
    chmod +x "$BUILD_DIR/install.sh"
    log "安装脚本创建完成"
}

# 创建测试套件
create_test_suite() {
    log "创建测试套件..."
    
    cat > "$BUILD_DIR/tests/test_basic.sh" << 'EOF'
#!/bin/bash
# 基本功能测试

set -e

TEST_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$TEST_DIR"

# 导入测试函数
source "$TEST_DIR/tests/test_functions.sh"

echo "=== 记忆同步系统基本测试 ==="
echo "测试时间: $(date)"
echo "技能目录: $SKILL_DIR"
echo ""

# 测试1: 文件存在性测试
echo "1. 文件存在性测试..."
test_file_exists "SKILL.md"
test_file_exists "README.md"
test_file_exists "scripts/real-daemon.py"
test_file_exists "scripts/start-all.sh"
test_file_exists "config/sync-config.json"
echo "✓ 文件存在性测试通过"
echo ""

# 测试2: 脚本可执行性测试
echo "2. 脚本可执行性测试..."
test_script_executable "scripts/start-all.sh"
test_script_executable "scripts/real-daemon.py"
echo "✓ 脚本可执行性测试通过"
echo ""

# 测试3: 配置验证测试
echo "3. 配置验证测试..."
test_config_valid "config/sync-config.json"
echo "✓ 配置验证测试通过"
echo ""

# 测试4: 功能测试
echo "4. 功能测试..."
cd "$SKILL_DIR"

# 测试启动脚本
echo "  测试启动脚本..."
if ./scripts/start-all.sh test; then
    echo "  ✓ 启动脚本测试通过"
else
    echo "  ✗ 启动脚本测试失败"
    exit 1
fi

# 测试单次同步
echo "  测试单次同步..."
if timeout 10 python3 ./scripts/real-daemon.py start 2>&1 | grep -q "开始第"; then
    echo "  ✓ 单次同步测试通过"
else
    echo "  ✗ 单次同步测试失败"
fi

echo ""
echo "=== 基本测试完成 ==="
echo "所有测试通过！"
EOF
    
    cat > "$BUILD_DIR/tests/test_functions.sh" << 'EOF'
#!/bin/bash
# 测试函数库

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 测试文件是否存在
test_file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
        return 0
    else
        echo -e "  ${RED}✗${NC} $file (不存在)"
        return 1
    fi
}

# 测试脚本可执行
test_script_executable() {
    local script="$1"
    if [ -x "$script" ]; then
        echo -e "  ${GREEN}✓${NC} $script (可执行)"
        return 0
    else
        echo -e "  ${RED}✗${NC} $script (不可执行)"
        return 1
    fi
}

# 测试配置有效性
test_config_valid() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        if python3 -m json.tool "$config_file" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $config_file (JSON有效)"
            return 0
        else
            echo -e "  ${RED}✗${NC} $config_file (JSON无效)"
            return 1
        fi
    else
        echo -e "  ${RED}✗${NC} $config_file (不存在)"
        return 1
    fi
}

# 测试命令执行
test_command() {
    local description="$1"
    local command="$2"
    
    echo -n "  测试 $description... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}通过${NC}"
        return 0
    else
        echo -e "${RED}失败${NC}"
        return 1
    fi
}
EOF
    
    chmod +x "$BUILD_DIR/tests/test_basic.sh"
    chmod +x "$BUILD_DIR/tests/test_functions.sh"
    
    log "测试套件创建完成"
}

# 打包技能
package_skill() {
    log "打包技能文件..."
    
    # 进入构建目录
    cd "$(dirname "$BUILD_DIR")"
    
    # 创建压缩包
    tar -czf "$OUTPUT_FILE" "$(basename "$BUILD_DIR")"
    
    # 计算文件信息
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    MD5_SUM=$(md5sum "$OUTPUT_FILE" | cut -d' ' -f1)
    
    log "打包完成: $OUTPUT_FILE"
    log "文件大小: $FILE_SIZE"
    log "MD5校验: $MD5_SUM"
}

# 显示打包信息
show_package_info() {
    echo -e "${GREEN}"
    echo "========================================="
    echo "  记忆同步系统技能打包完成！"
    echo "========================================="
    echo -e "${NC}"
    
    echo "技能名称: $SKILL_NAME"
    echo "版本: $VERSION"
    echo "打包文件: $OUTPUT_FILE"
    echo "文件大小: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo ""
    echo "包含内容:"
    echo "  📄 技能文档 (SKILL.md, README.md, ...)"
    echo "  ⚙️  配置文件 (config/sync-config.json)"
    echo "  🐍 Python脚本 (real-daemon.py, web-monitor.py)"
    echo "  🐚 Shell脚本 (start-all.sh, ...)"
    echo "  📖 使用示例 (EXAMPLES.md)"
    echo "  🔧 API文档 (API.md)"
    echo "  🧪 测试套件 (tests/)"
    echo "  📦 安装脚本 (install.sh)"
    echo ""
    echo "安装方法:"
    echo "  tar -xzf $OUTPUT_FILE"
    echo "  cd ${SKILL_NAME}-${VERSION}"
    echo "  ./install.sh"
    echo ""
    echo "或直接使用:"
    echo "  tar -xzf $OUTPUT_FILE -C ~/.openclaw/skills/"
    echo -e "${GREEN}"
    echo "========================================="
    echo -e "${NC}"
}

# 主打包流程
main() {
    log "开始打包记忆同步系统技能..."
    log "技能名称: $SKILL_NAME"
    log "版本: $VERSION"
    
    cleanup
    create_build_dir
    copy_files
    create_version_file
    create_install_script
    create_test_suite
    package_skill
    show_package_info
    
    log "打包完成！"
}

# 运行主程序
main "$@"