<div align="center">

# <img src="docs/images/logo.png" alt="" height="38" valign="middle" /> OpenChiip Harness

### 可自托管的智能体运行与编排框架。

OpenChiip Harness 是一个开箱即用的 AI 智能体运行时，将**大模型对话、技能编排、工具调用、多层记忆、多智能体协作、资源监控**整合进同一个进程，并自带一套完整的 React 管理后台。它既可以作为独立的本地 Agent 服务运行，也可以作为节点接入 OpenChiip 平台进行协同调度——通过出站 WebSocket 穿透 NAT，无需公网 IP。

无论你只想快速跑一个带 UI 的本地智能体，还是需要可编排、可审计、可崩溃恢复的任务执行引擎，OpenChiip Harness 都提供了从 CLI、HTTP/WS API 到桌面包的完整交付形态。

[![版本](https://img.shields.io/badge/version-0.0.30-blue.svg)](https://github.com/openchiip/harness)
[![许可证](https://img.shields.io/badge/License-AIGCGPL--1.0-green.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![平台](https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-lightgrey.svg)]()
![状态](https://img.shields.io/badge/status-active-success.svg)

[openchiip.com](https://www.openchiip.com) · [English](README.md)

</div>

<p align="center">
  <img src="docs/images/openchiip-harness-desktop.png" alt="OpenChiip Harness 桌面端" width="720" />
</p>

---

## 为什么选择 OpenChiip Harness？

- **一体化运行时** — LLM 对话、技能编排、工具调用、记忆、监控、管理 UI 全部集成在单一进程中，无需微服务 sprawl。

- **三层意图路由** — 规则 → 缓存 → LLM 逐级路由；命中技能走确定性 DAG 执行，未命中走 LLM Function Calling 多轮对话，兼顾稳定与灵活。

- **五原语能力治理** — Skill / MetaSkill / Tool / Command / A2A 通过统一的 CapabilityRegistry 注册、统一生命周期、统一 API 暴露。

- **多 Provider 子智能体** — 进程内、会话分叉、A2A 远程，并可委派给 Codex、Claude Code 等外部编码 CLI 协同完成任务。

- **崩溃恢复编排** — 拆解 → 执行 → 独立审计 → 结算 → 检查点。事件溯源会话日志支持精确回放与崩溃恢复。

- **双模式运行** — 独立模式（本地 FastAPI + Web UI）或平台协同模式（出站 WebSocket，穿透 NAT）。一条命令或 UI 切换即可转换模式。

---

## 核心特性

- **MCP 工具系统 + 自动安装探测** — 内置 shell / todo / web-search 工具，健壮探测（真实执行 `--version`、PATH 回退阶梯、Windows Store 假 exe 识别），支持一键安装 / 卸载 / 热注册。

- **守卫式工具管道** — pre/post 钩子链、超时保护、凭据清洗、可扩展审批流。

- **多层记忆 + 上下文压缩** — SQLite / RAG 持久化，长对话自动压缩。

- **Token 计量与预算熔断** — 成本可控，超额自动熔断。

- **轻量插件系统 + 可插拔提示词组装** — 按需扩展身份、工具与行为规则。

- **多形态交付** — pip、Docker、systemd 服务、Tauri 桌面应用、PyInstaller 单文件、Windows 安装包。

---

## 架构

```
openchiip-harness/
├── agent_runtime/       # Python 包（兼容现有部署路径）
│   ├── core/            # 核心引擎（LLM、Memory、DB、Config）
│   ├── server/          # FastAPI 后端（HTTP + WebSocket）
│   │   ├── api/         # 12 个 REST API 路由模块
│   │   └── ws_handler.py
│   ├── gateway/         # OpenChiip 平台网关（可选）
│   ├── orchestration/   # 编排引擎（DAG 执行）
│   ├── tools/           # MCP 工具注册
│   ├── metaskills/      # 元技能（7 个内置）
│   ├── skills/          # 技能包（用户安装）
│   ├── a2a/             # Agent-to-Agent 协作
│   ├── commands/        # 控制指令（8 个内置）
│   ├── monitor/         # 资源监控
│   ├── ws/              # WS 客户端（连接平台）
│   ├── main.py          # AgentApp 组装
│   ├── daemon.py        # 守护进程（兼容旧入口）
│   └── cli.py           # CLI 入口
├── web/                 # React + Vite 前端
├── desktop/             # Tauri 2.0 桌面应用
├── docker/              # Docker 配置
├── scripts/             # 安装脚本 + systemd 服务
└── pyproject.toml
```

---

## 快速开始

### pip 安装

```bash
pip install -e .
openchiip-harness init          # 交互式配置向导
openchiip-harness serve         # 启动服务器
```

访问：
- Web UI: http://localhost:8900
- API 文档: http://localhost:8900/docs

### Docker 运行

```bash
cd docker
cp .env.example .env          # 编辑填入 API Key
docker compose up -d
```

### 开发模式

```bash
# 后端
pip install -e .
uvicorn agent_runtime.server.app:create_app --factory --host 0.0.0.0 --port 8900

# 前端（另一个终端）
cd web
npm install
npm run dev                   # http://localhost:3000
```

---

## 跨平台安装

<details>
<summary><b>Linux</b> — tar.gz / deb / rpm / 一键脚本</summary>

**一键安装脚本：**

```bash
curl -fsSL https://get.openchiip.com | bash
# 或本地执行：
bash scripts/install.sh
```

安装器会在 `/opt/openchiip-harness` 创建虚拟环境，安装依赖，可选构建前端，并设置 systemd 服务。

**手动包安装：**

```bash
# 构建包
bash scripts/build-linux.sh 3.0.0

# 从 tar.gz 安装
tar xzf dist/openchiip-harness-3.0.0-linux-x86_64.tar.gz
cd openchiip-harness-3.0.0-linux-x86_64
./start.sh

# 或安装 deb/rpm（需要 fpm：gem install fpm）
sudo dpkg -i dist/openchiip-harness_3.0.0_x86_64.deb
sudo rpm -i dist/openchiip-harness-3.0.0-1.x86_64.rpm
```

**systemd 服务：**

```bash
sudo systemctl start openchiip-harness
sudo systemctl enable openchiip-harness   # 开机自启
```

</details>

<details>
<summary><b>Windows</b> — 便携包 / NSIS 安装包 / PyInstaller exe</summary>

**从源码构建：**

```cmd
scripts\build-windows.bat
```

这会在 `dist/` 目录生成三个产物：
- `openchiip-harness-3.0.0-windows-x64.zip` — 便携包（解压后运行 `start.bat`）
- `openchiip-harness-3.0.0-setup.exe` — NSIS 安装包（需要 NSIS：`choco install nsis`）
- `openchiip-harness.exe` — PyInstaller 单文件可执行程序

**手动安装：**

```powershell
pip install -e .
openchiip-harness init
openchiip-harness serve
```

**可选 CLI Agent 工具：**

```powershell
npm install -g @openai/codex @anthropic-ai/claude-code
```

</details>

<details>
<summary><b>macOS</b> — pip / Tauri 桌面应用</summary>

**pip 安装：**

```bash
pip install -e .
openchiip-harness init
openchiip-harness serve
```

**Tauri 桌面应用（即将推出）：**

```bash
cd desktop
npm install
npm run tauri dev     # 开发模式
npm run tauri build   # 生产构建
```

</details>

---

## CLI 命令参考

```bash
# 服务器
openchiip-harness init              # 初始化配置
openchiip-harness serve             # 启动 HTTP/WebSocket 服务器
openchiip-harness serve --platform wss://... --agent-id emp.xxx  # 平台协同模式
openchiip-harness run <agent_id>    # 兼容旧模式（纯 WS 客户端）

# 对话
openchiip-harness chat "你好"       # 命令行对话
openchiip-harness chat -i           # 交互模式

# 管理
openchiip-harness status            # 查看状态
openchiip-harness skills list       # 技能列表
openchiip-harness metaskills list   # 元技能列表
openchiip-harness metaskills run <name> --args '{"path":"/tmp"}'
openchiip-harness cmd /status       # 执行控制指令
openchiip-harness a2a card          # 查看 Agent 名片
openchiip-harness tools list        # 工具列表
openchiip-harness memory search "关键词"

# 配置
openchiip-harness config get llm.model_name
openchiip-harness config set llm.api_key sk-xxx
```

---

## 双模式运行

**独立模式**（默认）：

```bash
openchiip-harness serve
# 本地 FastAPI 服务器，前端直接访问
```

**平台协同模式**：

```bash
openchiip-harness serve --platform wss://platform.example.com/ws --agent-id emp.zhangsan
# 同时启动本地服务器 + 连接 OpenChiip 平台
```

你也可以从 Web UI 侧边栏切换模式。提供三种工作模式：
- **本地模式** — 独立运行，不连接平台
- **平台协同模式** — 连接平台，双向同步
- **接单模式** — 仅处理平台委派的项目任务（不接受对话请求）

---

## 内置能力

### 7 个元技能（MetaSkill，免 LLM）

| 名称 | 功能 | 免 LLM |
|------|------|--------|
| `metaskill.env.check` | 检查命令是否存在及版本 | ✅ |
| `metaskill.file.find` | 文件搜索 | ✅ |
| `metaskill.file.grep` | 文件内容搜索 | ✅ |
| `metaskill.file.list` | 目录列表 | ✅ |
| `metaskill.file.read` | 读取文件 | ✅ |
| `metaskill.file.write` | 写入文件 | ✅ |
| `metaskill.shell.exec` | 执行 Shell 命令 | ✅ |

### 8 个控制指令（Command）

`/status` `/skills` `/reload` `/learn` `/explore` `/fallback` `/trace` `/help`

---

## 管理后台

管理后台包含 16 个页面：

| 页面 | 说明 |
|------|------|
| 对话 | 与 Agent 智能交互 |
| 会话 | 管理对话会话历史 |
| 技能 | 安装/卸载/测试业务执行技能 |
| 元技能 | 管理可复用的基础能力原语 |
| 指令 | 自然语言快捷指令管理 |
| 工具 | MCP 工具管理 |
| 协作 | 跨 Agent 调用与授权 |
| 记忆 | Agent 记忆查看与管理 |
| 活动 | 近期操作记录 |
| 监控 | CPU / 内存 / 磁盘资源监控 |
| 项目 | Agent 项目管理与监控 |
| 任务 | 跨项目任务汇总与跟踪 |
| 模型提供商 | LLM 模型提供商配置 |
| 仓库凭据 | Git 仓库访问凭据管理 |
| 仪表盘 | 系统概览 |
| 设置 | 运行时配置管理 |

---

## API 端点

| 模块 | 路径前缀 | 端点数 | 说明 |
|------|---------|--------|------|
| Chat | `/api/v1/chat` | 2 | 非流式 + SSE 流式对话 |
| Sessions | `/api/v1/sessions` | 4 | 会话 CRUD + 消息历史 |
| Skills | `/api/v1/skills` | 5 | 技能安装/卸载/测试 |
| MetaSkills | `/api/v1/metaskills` | 4 | 元技能列表/执行/安装 |
| Commands | `/api/v1/commands` | 3 | 控制指令执行 |
| Tools | `/api/v1/tools` | 5 | MCP 工具管理 |
| A2A | `/api/v1/a2a` | 5 | Agent 名片/发现/调用 |
| Memory | `/api/v1/memory` | 4 | 记忆查询/搜索 |
| Knowledge | `/api/v1/knowledge` | 3 | 知识库管理 |
| Config | `/api/v1/config` | 2 | 运行时配置 |
| Monitor | `/api/v1/monitor` | 1 | CPU/内存/磁盘 |
| Status | `/api/v1/status` | 1 | 运行状态 |
| WebSocket | `/ws` | 1 | 前端实时通信 |

---

## 配置

配置文件位于 `~/.openchiip-harness/config.yaml`：

```yaml
server:
  host: 127.0.0.1
  port: 8900
  cors_origins: ["*"]

llm:
  provider: baidu              # baidu / openai / custom
  model_name: ernie-5.1
  fast_model_name: ernie-4.5-turbo-128k
  api_key: your-api-key
  model_server: ""             # 自定义 API 地址（可选）

platform:
  enabled: false
  ws_url: ""
  agent_id: ""

storage:
  data_dir: ~/.openchiip-harness/data
```

---

## 技术栈

| 层 | 技术 |
|----|------|
| 后端 | Python 3.10+ · FastAPI · uvicorn · SQLite · WebSocket |
| 前端 | React 18 · TypeScript · Vite · Tailwind CSS · Zustand · TanStack Query |
| 桌面 | Tauri 2.0 (Rust) |
| LLM | 百度文心 ERNIE · OpenAI · 任意 OpenAI 兼容接口 |

---

## 兼容性

- 内层 `agent_runtime/` 包名不变，所有现有 import 路径有效
- 现有 `daemon.py` 入口保留，`agent-runtime emp.zhangsan` 行为不变
- systemd 服务、部署目录结构无需改动

---

## 贡献

欢迎贡献代码！请确保你的代码遵循现有风格并包含适当的测试。

---

## 许可证

基于 [AIGCGPL-1.0](LICENSE)（人工智能生成代码通用公共许可证）授权。

Copyright © 2024 OpenChiip. All rights reserved.
