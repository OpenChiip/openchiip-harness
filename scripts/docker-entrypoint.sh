#!/bin/bash
# OpenChiip Harness — 容器入口脚本
#
# 职责：
#   1. 加载平台下发的 agent.env（密钥/环境变量），注入到进程环境
#   2. 初始化 Docker 预装工具记录（把镜像内已存在的 CLI Agent 标记为 installed）
#   3. exec 主命令（默认 `openchiip-harness serve ...`）
#
# 设计原则：任何一步失败都不得阻断容器启动（工具记录初始化失败仅告警）。
set -e

# 运行时数据目录（与 RuntimeConfig.runtime_home 对齐，默认含 /data 子目录）
RUNTIME_HOME="${AGENT_RUNTIME_HOME:-${RUNTIME_HOME:-$HOME/.openchiip-harness/data}}"
# Harness 根目录（agent.env 约定存放于 runtime_home 的上一级）
HARNESS_HOME="${RUNTIME_HOME%/data}"

mkdir -p "$RUNTIME_HOME"

# ── 1. 加载平台下发的环境变量 ──
# 依次探测候选路径，命中第一个存在的 agent.env 即加载（set -a 自动导出）
for env_file in \
    "${HARNESS_HOME}/agent.env" \
    "${RUNTIME_HOME}/agent.env" \
    "${HOME}/.openchiip-harness/agent.env"; do
    if [ -f "$env_file" ]; then
        # shellcheck disable=SC1090
        set -a
        . "$env_file"
        set +a
        echo "[entrypoint] 已加载环境变量: $env_file"
        break
    fi
done

# ── 2. 初始化 Docker 预装工具记录（标记为 installed + docker-preinstall）──
# 无 tools.db / 探测失败均不阻断启动（|| true）
if python -m agent_runtime.cli init-tools --source docker-preinstall 2>/dev/null; then
    echo "[entrypoint] 预装工具记录已初始化"
else
    echo "[entrypoint] 预装工具记录初始化跳过（可稍后在工具管理页面处理）"
fi

# ── 3. 启动主服务 ──
exec "$@"
