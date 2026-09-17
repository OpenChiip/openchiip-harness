# OpenChiip Harness — Docker 镜像
# 多阶段构建：前端编译 + 后端运行

# ── Stage 1: 前端构建 ──
FROM node:20-alpine AS frontend-builder
WORKDIR /build/web
COPY web/package.json web/package-lock.json* ./
# 国内镜像加速，国际用户可替换为 https://registry.npmjs.org
RUN npm ci --registry=https://registry.npmmirror.com
COPY web/ .
RUN npm run build

# ── Stage 2: Python 运行 ──
FROM python:3.12-slim

LABEL maintainer="OpenChiip <https://github.com/openchiip>"
LABEL description="OpenChiip Harness — 智能体运行框架"

# 系统依赖 + Node.js 20.x（用于 npm install -g CLI Agent 工具）
# 合并到单条 RUN 指令以减少镜像层数
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm config set registry https://registry.npmmirror.com \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 预装常用 CLI Agent（版本策略参照 vibe-kanban，使用 npmmirror 加速国内下载）
# 网络异常时不阻断镜像构建：预装失败仍可在前端工具管理页一键安装
RUN npm install -g @openai/codex@latest @anthropic-ai/claude-code@latest \
    && npm cache clean --force \
    || (npm cache clean --force || true; \
        echo '⚠ CLI Agent 预装失败（网络原因），可稍后在工具管理页面安装'; exit 0)

# Python 依赖
WORKDIR /app
COPY pyproject.toml .
COPY agent_runtime/ agent_runtime/

# 安装 Python 包（国内使用阿里云镜像加速，国际用户可移除 -i 和 --trusted-host 参数使用默认 PyPI）
RUN pip install --no-cache-dir \
    --timeout 120 --retries 5 \
    -i https://mirrors.aliyun.com/pypi/simple/ \
    --trusted-host mirrors.aliyun.com \
    -e .

# 复制前端构建产物
COPY --from=frontend-builder /build/web/dist /app/web/dist

# 容器入口脚本：加载 agent.env + 初始化预装工具记录
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 数据卷
VOLUME /app/data

# 环境变量
ENV AGENT_RUNTIME_HOME=/app/data \
    PYTHONUNBUFFERED=1

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://127.0.0.1:8900/api/v1/status || exit 1

EXPOSE 8900

# 入口脚本负责环境变量加载与预装工具记录初始化，再执行 CMD
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# 默认命令：启动服务器
CMD ["openchiip-harness", "serve", "--host", "0.0.0.0", "--port", "8900"]
