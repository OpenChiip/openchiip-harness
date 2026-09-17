# Step 3：对抗验证

你现在是苛刻的安全审查员。逐项审查下面的 Skill Package，找出会导致执行失败或安全事故的问题。

## 待审查的 Skill Package

{{PACKAGE}}

## 审查清单

1. **变量完整性**：`${var}` 引用的变量是否都由前置步骤的 output_key 或技能 inputs 提供？depends_on 是否覆盖所有数据依赖？
2. **循环依赖**：depends_on 是否成环？
3. **危险命令**：shell_command 是否含 rm/mv/sudo/chmod/wget/curl 管道执行等危险操作？
4. **action 合法性**：action 是否属于 shell_command/template_render/write_file/table_lookup/llm_generate 五种？必填字段是否齐全？
5. **final_output**：是否指向真实存在的 output_key？
6. **最小 LLM 原则**：是否存在可用 Layer 1/2 步骤替代的冗余 llm_generate？

## 输出要求

输出严格 JSON，不要任何其他文字：

```json
{
  "passed": true或false,
  "issues": [
    {"step": "步骤 id", "severity": "high/medium/low", "problem": "问题描述", "suggestion": "修复建议"}
  ],
  "fixed_package": {
    "manifest": { "修正后的 manifest（无问题时为 null）" },
    "action_graph": { "修正后的 action_graph（无问题时为 null）" }
  }
}
```

若没有任何问题：`{"passed": true, "issues": [], "fixed_package": null}`
