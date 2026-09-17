#!/usr/bin/env bash
# OpenChiip Harness — 一键安装脚本
# 用法：curl -fsSL https://get.openchiip.com | bash
#    或：bash scripts/install.sh
set -euo pipefail

INSTALL_DIR="${OPENCHIIP_INSTALL:-/opt/openchiip-harness}"
PYTHON="${PYTHON:-python3}"
NODE="${NODE:-node}"
BRANCH="${OPENCHIIP_BRANCH:-main}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# 交互式确认（仅在 TTY 下提示；非交互环境（curl|bash）默认否）
ask_yes_no() {
    local prompt="$1" reply
    if [[ ! -t 0 ]]; then
        return 1
    fi
    read -r -p "$(echo -e "${YELLOW}${prompt} [y/N]:${NC} ")" reply || return 1
    [[ "$reply" =~ ^[Yy]$ ]]
}

# ── 检查依赖 ──
check_deps() {
    info "检查依赖..."

    # Python
    if ! command -v "$PYTHON" &>/dev/null; then
        err "未找到 Python 3，请先安装: https://python.org/downloads/"
    fi
    PY_VERSION=$($PYTHON -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
    if [[ "$PY_MAJOR" -lt 3 ]] || { [[ "$PY_MAJOR" -eq 3 ]] && [[ "$PY_MINOR" -lt 10 ]]; }; then
        err "需要 Python 3.10+，当前版本: $PY_VERSION"
    fi
    ok "Python $PY_VERSION"

    # Node (可选，用于前端开发)
    if command -v "$NODE" &>/dev/null; then
        NODE_VERSION=$($NODE --version | sed 's/v//')
        ok "Node.js $NODE_VERSION"
    else
        warn "Node.js 未安装（前端开发需要，运行模式不需要）"
    fi
}

# ── 安装 ──
install() {
    info "安装 OpenChiip Harness..."

    # 创建安装目录
    sudo mkdir -p "$INSTALL_DIR"
    sudo chown -R "$(whoami)" "$INSTALL_DIR"

    # 复制文件
    info "复制文件到 $INSTALL_DIR..."
    cp -r agent_runtime pyproject.toml "$INSTALL_DIR/"

    # 创建虚拟环境
    if [[ ! -d "$INSTALL_DIR/venv" ]]; then
        info "创建 Python 虚拟环境..."
        $PYTHON -m venv "$INSTALL_DIR/venv"
    fi

    # 激活虚拟环境并安装
    source "$INSTALL_DIR/venv/bin/activate"
    info "安装 Python 依赖..."
    pip install --upgrade pip -q
    pip install -e "$INSTALL_DIR" -q

    # 创建 bin 链接
    mkdir -p "$INSTALL_DIR/bin"
    ln -sf "$INSTALL_DIR/venv/bin/openchiip-harness" "$INSTALL_DIR/bin/openchiip-harness"
    ln -sf "$INSTALL_DIR/venv/bin/agent-runtime" "$INSTALL_DIR/bin/agent-runtime"

    ok "Python 包安装完成"

    # 构建前端（如果 Node 可用）
    if command -v "$NODE" &>/dev/null && [[ -d "$INSTALL_DIR/../web" ]]; then
        info "构建前端..."
        (cd "$INSTALL_DIR/../web" && npm install -q && npm run build) || warn "前端构建失败（可稍后手动构建）"
    fi
}

# ── 可选：安装 AI Agent CLI 工具 ──
# 环境变量 INSTALL_CLI_AGENTS=yes 可强制安装；否则在交互环境下询问
install_cli_agents() {
    local want="${INSTALL_CLI_AGENTS:-}"
    if [[ "$want" != "yes" ]]; then
        if ! ask_yes_no "是否预装 AI Agent CLI 工具（Codex、Claude Code）？"; then
            return 0
        fi
    fi

    info "安装 AI Agent CLI 工具..."
    if command -v npm &>/dev/null; then
        if npm install -g @openai/codex @anthropic-ai/claude-code 2>/dev/null; then
            ok "Codex CLI 和 Claude Code 安装成功"
        else
            warn "部分工具安装失败，可稍后在工具管理页面手动安装"
        fi
    else
        warn "npm 不可用，跳过 CLI Agent 安装。请手动安装 Node.js 后重试。"
    fi
}

# ── 初始化配置 ──
init_config() {
    info "初始化配置..."
    "$INSTALL_DIR/bin/openchiip-harness" init --force 2>/dev/null || {
        # 非交互模式：创建默认配置
        mkdir -p ~/.openchiip-harness/data
        cat > ~/.openchiip-harness/config.yaml << 'YAML'
server:
  host: 0.0.0.0
  port: 8900
  cors_origins: ["*"]
llm:
  provider: baidu
  model_name: ernie-5.1
  fast_model_name: ernie-4.5-turbo-128k
  api_key: ""
platform:
  enabled: false
storage:
  data_dir: ~/.openchiip-harness/data
YAML
        ok "默认配置已创建（请编辑 ~/.openchiip-harness/config.yaml 填入 API Key）"
    }
}

# ── 安装 systemd 服务（Linux）──
install_service() {
    if [[ "$(uname)" != "Linux" ]]; then
        return
    fi
    if ! command -v systemctl &>/dev/null; then
        return
    fi

    info "安装 systemd 服务..."
    sudo cp "$INSTALL_DIR/../scripts/openchiip-harness.service" /etc/systemd/system/ 2>/dev/null || \
    sudo cp scripts/openchiip-harness.service /etc/systemd/system/ 2>/dev/null || {
        warn "systemd 服务文件未找到，跳过"
        return
    }
    sudo systemctl daemon-reload
    sudo systemctl enable openchiip-harness
    ok "systemd 服务已安装并设为开机启动"
    info "启动服务: sudo systemctl start openchiip-harness"
}

# ── 完成 ──
done_msg() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  OpenChiip Harness 安装完成！${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    echo "  启动服务器:  openchiip-harness serve"
    echo "  访问 Web UI: http://localhost:8900"
    echo "  查看状态:    openchiip-harness status"
    echo "  配置向导:    openchiip-harness init --force"
    echo "  API 文档:    http://localhost:8900/docs"
    echo ""
}

# ── Main ──
main() {
    echo ""
    echo "╔═══════════════════════════════════════╗"
    echo "║     OpenChiip Harness Installer       ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""

    check_deps
    install
    install_cli_agents
    init_config
    install_service
    done_msg
}

main "$@"
