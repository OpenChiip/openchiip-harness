# OpenChiip Agent 架构文档

> v3.2 — 借鉴 deepseek-harness 的企业级 Agent 框架升级

## 架构概览

```
┌─────────────────────────────────────────────────────────┐
│                    前端 (React + Vite)                    │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ Sidebar  │  │   ChatView   │  │  Details Panel    │  │
│  │ (可折叠) │  │ (事件驱动)   │  │ (工具调用详情)    │  │
│  └──────────┘  └──────────────┘  └───────────────────┘  │
│       ↕ Conversation Node 注册表 (可插拔渲染器)           │
└─────────────────────────────────────────────────────────┘
                          ↕ WebSocket / REST API
┌─────────────────────────────────────────────────────────┐
│                  Agent Runtime (Python)                   │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │                  AgentApp (组装层)                   │  │
│  │  ┌──────────┐ ┌──────────┐ ┌───────────────────┐  │  │
│  │  │ Plugin   │ │ Prompt   │ │ Capability        │  │  │
│  │  │ Manager  │ │Assembler │ │ Registry          │  │  │
│  │  └──────────┘ └──────────┘ │ ┌─────┐ ┌──────┐ │  │  │
│  │                             │ │Skill│ │Tool  │ │  │  │
│  │  ┌──────────┐ ┌──────────┐ │ └─────┘ └──────┘ │  │  │
│  │  │Compaction│ │Subagent  │ │ ┌─────┐ ┌──────┐ │  │  │
│  │  │Provider  │ │Manager   │ │ │Meta │ │Cmd   │ │  │  │
│  │  └──────────┘ │          │ │ │Skill│ │      │ │  │  │
│  │               │┌────────┐│ │ └─────┘ └──────┘ │  │  │
│  │  ┌──────────┐ ││InProc  ││ │ ┌─────┐          │  │  │
│  │  │ Session  │ ││A2A     ││ │ │A2A  │          │  │  │
│  │  │ Fork     │ ││Fork    ││ │ └─────┘          │  │  │
│  │  └──────────┘ │└────────┘│ └───────────────────┘  │  │
│  │               └──────────┘                         │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │               Agent Loop (Turn/Step)                │  │
│  │  turn_start → step_start → LLM → tools → step_end  │  │
│  │  → turn_end                                         │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ SessionLog   │  │ToolPipeline  │  │MemoryManager │   │
│  │(Event Source)│  │(Guard Chain) │  │(SQLite+RAG)  │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│                    持久化层 (SQLite)                       │
│  conversations │ execution_logs │ session_events │ ...   │
└─────────────────────────────────────────────────────────┘
```

## 核心模块

### v3.0 — 基础框架
| 模块 | 文件 | 职责 |
|------|------|------|
| RuntimeConfig | `core/config.py` | 运行时配置 |
| Database | `core/db.py` | SQLite 持久化 |
| LLMClient | `core/llm_client.py` | LLM 调用 + Token 计量 |
| MemoryManager | `core/memory.py` | 多层记忆管理 |
| DAGExecutor | `core/dag_executor.py` | 技能 DAG 执行 |
| SkillManager | `core/skill_manager.py` | 技能管理 |
| MetaSkillRegistry | `core/metaskill_registry.py` | 元技能注册 |
| IntentRouter | `core/intent_router.py` | 三层意图路由 |

### v3.1 — 借鉴升级
| 模块 | 文件 | 职责 |
|------|------|------|
| SessionLog | `core/session_log.py` | 事件溯源会话日志 |
| ToolPipeline | `core/tool_pipeline.py` | 守卫工具执行管道 |
| CapabilityRegistry | `core/capability.py` | 统一能力注册表 |
| PluginManager | `core/plugin_system.py` | 轻量插件系统 |
| PromptAssembler | `core/prompt_assembler.py` | 可插拔提示词组装 |

### v3.2 — 高级特性
| 模块 | 文件 | 职责 |
|------|------|------|
| CompactionProvider | `core/compaction.py` | 上下文压缩 |
| SubagentManager | `core/subagent.py` | 子 Agent 多 Provider |
| SessionFork | `core/session_fork.py` | 会话分叉/恢复 |

## 能力治理五原语

所有能力原语通过 `CapabilityRegistry` 统一管理：

| 原语 | Provider | 注册来源 |
|------|----------|----------|
| 技能 (Skill) | `SkillProvider` | `SkillManager` |
| 元技能 (MetaSkill) | `MetaSkillProvider` | `MetaSkillRegistry` |
| 工具 (Tool) | `ToolProvider` | `ToolRegistry` |
| 指令 (Command) | `CommandProvider` | `CommandRegistry` |
| 协作 (A2A) | `A2AProvider` | `A2ACaller` |

## 前端架构

### Conversation Node 注册表

```
web/src/components/conversation/
├── types.ts              # 事件类型定义
├── ChatView.tsx          # 事件驱动对话视图
├── TurnStatus.tsx        # Turn 级别状态指示
├── QuestionComposer.tsx  # Agent 提问交互
├── index.ts              # 模块导出
└── nodes/
    ├── registry.tsx      # 节点注册表
    ├── UserMessageNode.tsx
    ├── AssistantMessageNode.tsx
    ├── ToolCallNode.tsx   # 含 ToolCallTree 递归
    ├── TurnBoundaryNode.tsx
    └── ErrorNode.tsx
```

### 布局组件

```
web/src/components/
├── Layout.tsx            # 侧边栏导航
├── ResizablePanel.tsx    # 可拖拽调整面板
└── conversation/         # 对话渲染系统
```

## API 端点

### 新增端点
| 端点 | 方法 | 职责 |
|------|------|------|
| `/api/capabilities` | GET | 列出所有能力 |
| `/api/capabilities/counts` | GET | 按类型统计 |
| `/api/capabilities/health` | GET | 健康检查 |
| `/api/capabilities/{name}` | GET | 单个能力详情 |
| `/api/capabilities/{name}/invoke` | POST | 调用能力 |
| `/api/session-events/{id}` | GET | 获取事件列表 |
| `/api/session-events/{id}/messages` | GET | 派生 LLM 消息 |
| `/api/session-events/{id}/tool-summary` | GET | 工具调用摘要 |
| `/api/session-events/{id}/stats` | GET | 会话统计 |
| `/api/session-events/{id}/fork` | POST | 会话分叉 |

## 设计决策记录

### ADR-001: 事件溯源会话日志
- **决策**: 采用 append-only 事件日志，LLM 历史从事件派生
- **理由**: 支持精确回放、崩溃恢复、会话分叉
- **替代方案**: 传统消息列表存储（无法回放、无法分叉）

### ADR-002: 守卫工具管道
- **决策**: 工具执行通过 pre/post 钩子链
- **理由**: 安全守卫、超时保护、可扩展审批流
- **替代方案**: 直接 dispatch（无安全控制）

### ADR-003: 统一能力注册表
- **决策**: 五大原语统一通过 CapabilityRegistry 管理
- **理由**: 统一 API、统一生命周期、可插拔
- **替代方案**: 各原语独立注册（无法统一管理）

### ADR-004: 前端 Conversation Node 注册表
- **决策**: 每种事件类型注册一个渲染器
- **理由**: 可扩展、可插拔、新事件类型只需注册新渲染器
- **替代方案**: 硬编码 if/else 分支

### ADR-005: 子 Agent 多 Provider
- **决策**: 支持 InProcess/A2A/Fork 三种 Provider
- **理由**: 不同场景需要不同的子 Agent 模式
- **替代方案**: 仅支持 A2A 远程调用
