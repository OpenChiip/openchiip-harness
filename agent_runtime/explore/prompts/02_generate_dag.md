# Step 2：DAG 生成

根据任务描述与已提取的概念，生成 Skill Package（manifest + action_graph）。

## 任务描述

{{TASK}}

## 已提取概念

{{CONCEPTS}}

## 技能规范（必须严格遵守）

manifest.json 结构：

```json
{
  "name": "技能名",
  "version": "0.1.0",
  "description": "中文描述",
  "author": "explore",
  "applicable_when": [
    {"intent": "意图名", "keywords": [], "context_keywords": []}
  ],
  "token_budget": {"normal": 600},
  "inputs": {"user_instruction": "用户原始指令文本"}
}
```

action_graph.json 结构：`{"description": "...", "steps": [...], "final_output": "最后一步的 output_key"}`

每个 step 的 action 只能是以下 5 种之一：

1. `shell_command`（Layer 1，确定性优先）：字段 `command`、`capture: "stdout"`、`output_key`
2. `template_render`（Layer 1）：字段 `template`（内含 ${var}）、`output_key`
3. `write_file`（Layer 2）：字段 `path`、`content`（可含 ${var}）、`output_key`
4. `table_lookup`（Layer 2）：字段 `table`、`lookup_key`、`value`、`output_key`
5. `llm_generate`（Layer 3，仅当确定性步骤无法完成时）：字段 `system_prompt`、`user_prompt`（可含 ${var}）、`output_key`

通用字段：`id`（snake_case 唯一）、`layer`（1/2/3）、`description`、`depends_on`（依赖的步骤 id 数组）。

## 设计原则

- **确定性优先**：能用 shell/模板解决的绝不交给 LLM，LLM 步骤越少越好
- 变量引用一律 `${output_key}` 形式；步骤间数据流必须通过 depends_on 声明
- shell 命令只用常见系统命令（date/ls/whoami/df/uptime 等），禁止 rm/mv/sudo/网络下载
- 路径不得硬编码用户名，家目录用 `~`

## 输出要求

输出严格 JSON，不要任何其他文字：

```json
{
  "manifest": { ... },
  "action_graph": { ... }
}
```
