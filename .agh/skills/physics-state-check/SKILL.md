---
name: physics-state-check
description: '物理任务专属状态机初始化：创建/校验本任务专属的 problem_state.json，管理会话状态并隔离历史题目数据。'
---

### State Check (Task Isolation & Session Bootstrapping)

在启动任何复杂的物理分析、数值求解或竞赛建模任务时，首要步骤是确认并初始化该任务的单一状态真源：`problem_state.json`。

1. **全新任务初始化与目录隔离**：
   - 从 `physics-agent/runtime/problem_state_template.json` 复制一份空白骨架；
   - 必须保存在专属子目录下：`physics-agent/runtime/<task-slug>/problem_state.json`（`<task-slug>` 为任务主题英文简述，如 `kepler-orbit`、`wave-optics`、`space-diving`）；
   - 本任务产生的所有文件（代码、日志、图表、中间报告）统一存放在 `<task-slug>/` 文件夹内，绝对禁止平铺于根目录；
   - 严禁直接套用其他无关历史题目的状态文件，确保任务之间物理假设与参数彻底隔离。

2. **会话标识（Session Key）记录**：
   - 若会话环境中提供了唯一 session key，写入 `problem_state.json` 的 `session_key` 字段；
   - 若无法获取，填 `null` 并通过 `audit_log.py` 记录说明，不臆造或虚构伪 session key。

3. **历史阶段断点续跑（Resume from Stage）**：
   - 若本任务已存在执行中的 `problem_state.json`，读取当前 `stage`（如 `node_2b_modeling`），直接从该阶段断点续跑，不重复推导前序已验证节点。
