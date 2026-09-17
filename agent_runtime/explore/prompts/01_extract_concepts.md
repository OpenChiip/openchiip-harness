# Step 1：概念提取

从以下任务描述中提取可固化的技能概念。

## 任务描述

{{TASK}}

## 输出要求

输出严格 JSON，不要任何其他文字：

```json
{
  "skill_name": "snake_case 英文技能名（如 daily_report）",
  "description": "一句话中文描述该技能做什么",
  "intent": "snake_case 意图名",
  "keywords": ["用户触发该技能的中文关键词，5-8 个"],
  "context_keywords": ["辅助上下文关键词，可为空数组"],
  "inputs": {"输入变量名": "变量含义说明"},
  "outputs": "最终交付物的一句话描述"
}
```

## 约束

- skill_name 只允许小写字母、数字、下划线
- 关键词必须贴近用户真实说法（口语化）
- 只提取确定性强的概念，不要臆测任务之外的能力
