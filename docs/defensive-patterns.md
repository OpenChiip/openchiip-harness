# 防御性编程模式

借鉴 deepseek-harness 的 `defensive-patterns.md`，适用于 openchiip-harness 的关键规则。

## 1. 正交结果独立报告

**原则**: 一个结果可能同时是多种事实，不要互斥报告。

**应用**: `ToolResult` 应独立报告 timeout/signal/exitCode，
而不是用一个 `status` 字段互斥表示。

```python
# 正确
@dataclass
class ToolResult:
    success: bool
    data: Any
    error: Optional[str]
    timed_out: bool          # 独立标志
    rejected: bool           # 独立标志
    duration_ms: float

# 错误 — 互斥状态丢失信息
@dataclass
class ToolResult:
    status: str  # "ok" | "timeout" | "rejected" | "error"
```

## 2. 回调异常隔离

**原则**: 用户监听器抛异常不能影响核心流程。

**应用**: SessionLog 的事件分发、PluginBus 的事件发布、
CapabilityRegistry 的钩子调用，都必须 try/except 包裹。

```python
def _notify_listeners(self, event_type, data):
    for listener in self._listeners:
        try:
            listener(event_type, data)
        except Exception:
            logger.debug('监听器异常（已隔离）', exc_info=True)
```

**检查清单**:
- [x] `SessionLog._notify()` — 异常隔离
- [x] `PluginBus.emit()` — 异常隔离
- [x] `CapabilityRegistry._fire_hooks()` — 异常隔离
- [x] `CompactionProvider._notify()` — 异常隔离
- [ ] 工具执行回调 — 待补充

## 3. 凭据清洗

**原则**: 子进程拿到的环境变量必须清洗，不能泄露密钥。

**应用**: shell 工具执行前过滤 `*KEY*`、`*SECRET*`、`*TOKEN*` 等环境变量。

```python
import os
import re

_CREDENTIAL_PATTERNS = re.compile(r'(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL)', re.I)

def sanitize_env(env: dict) -> dict:
    """清洗环境变量，移除可能包含凭据的条目。"""
    return {
        k: v for k, v in env.items()
        if not _CREDENTIAL_PATTERNS.search(k)
    }
```

**应用位置**: `ToolPipeline` 的 shell 执行钩子。

## 4. Dispose 要等到静止

**原则**: teardown 不能只发 kill 就返回，要等待所有任务完成。

**应用**: WebSocket 关闭时要 await 所有进行中的任务。

```python
async def graceful_shutdown(self):
    """优雅关闭：等待所有进行中的任务完成。"""
    self._accepting = False
    
    # 等待进行中的 turn 完成
    for task in self._active_turns:
        try:
            await asyncio.wait_for(task, timeout=30.0)
        except asyncio.TimeoutError:
            task.cancel()
    
    # 等待所有 WebSocket 连接关闭
    for ws in self._connections:
        await ws.close()
```

## 5. 输入验证前置

**原则**: 在边界处验证输入，内部代码信任已验证的数据。

**应用**: API 端点、WebSocket 消息处理、工具参数解析。

```python
# API 边界验证
def validate_tool_call(data: dict) -> ToolCall:
    if 'name' not in data:
        raise ValueError('缺少工具名称')
    if not isinstance(data['name'], str):
        raise ValueError('工具名称必须是字符串')
    if len(data['name']) > 200:
        raise ValueError('工具名称过长')
    return ToolCall(...)
```

## 6. 幂等操作

**原则**: 网络操作和状态变更应尽量设计为幂等。

**应用**: 
- SessionLog.append 使用 (session_id, seq) 唯一索引
- 能力注册使用 name 作为唯一键
- 插件激活支持重复调用（幂等）

## 7. 超时 everywhere

**原则**: 每个外部调用都应有超时。

**应用**:
- LLM 请求超时
- 工具执行超时（ToolPipeline 已内置）
- WebSocket 心跳超时
- 子 Agent 调用超时
- HTTP API 调用超时
