---
name: physics-auditability
description: '物理任务可追溯性与运行留痕：状态机写回读回校验、调用 audit_log.py 记录面向用户的纯正中文物理审计说明、现场脚本 runlog.py 生成与数值结论回溯锚定。'
---

### Auditability & Traceability（可审计性与运行留痕铁律）

为了保证科研结论可复现、严禁暗箱操作或黑盒编造，在物理分析过程中必须严格遵守以下五大留痕规范：

---

## 1. 单一状态真源与任务隔离 (Single Source of Truth)

每个物理任务在专属子目录 `physics-agent/runtime/<task-slug>/problem_state.json` 中维护唯一状态真源。
- 完整包含字段：`task`, `session_key`, `stage`, `quota`, `hypothesis_layer`, `dimensional_table`, `internal_prior`, `knowledge_routing`, `data_source_decision`, `numerical_artifacts`, `audit_logs`, `anomalies`, `verification`, `report`；
- 所有改动均基于该文件增量更新，杜绝多份散落状态。

---

## 2. 写回即读回校验 (Write-Back Verification)

- 每次调用 `write` 或 `edit` 修改 `problem_state.json` 或任务参数文件后，**必须立即调用 `read` 工具核对目标字段是否已真实更新**；
- 若读回值仍为旧值或为空，严禁假定写入成功，必须立即停下排查文件权限或路径错误。

---

## 3. 中文物理审计记录规范 (Chinese Audit Logs via `audit_log.py`)

- 凡是发生数据源决策、知识路由、门禁调用、或模型求解运行，必须通过调用 `physics-agent/hooks/audit_log.py` 追加结构化审计记录，严禁手工修改 `audit_logs` 数组；
- **纯正简体中文铁律**：每条审计记录中的 `args.note` 必须使用面向用户可读的规范简体中文（1–2 句清晰总结本次调用的物理目的与核心结果）；
- **严禁英文段落与内部黑话**：绝对禁止在 `note` 中输出大段英文，绝对禁止出现 `Level 0`、`Node 1.5`、`A4 6-key extras attached` 等开发侧内部黑话；
- **合规中文范例**：
  - 数据源记录：`note: "调取美国标准大气模型 1976 标准数据，并以双体弹性飞掠解析上界作为独立验证基准。"`
  - 求解与调试记录：`note: "第 2 次运行单缝衍射光强积分程序：修正波长单位换算系数后重新求解，中央明纹半角宽度为 0.0055 rad，与理论瑞利判据残差小于 0.1%。"`

---

## 4. 6 扩展键与现场运行资产同步生成 (`runlogs/<artifact_id>.txt`)

- 执行任何 Python 脚本时，调用 `audit_log.py` 必须附带 6 个扩展键：`script_path`, `stdin_or_argv`, `stdout_tail`, `stderr`, `exit_code`, `iteration_index`；
- **记录演化历程，严禁抹杀调试过程**：严禁在多次调试调优后只留下一条最终记录！每一次初版尝试、报错排查、收敛迭代都应分配递增的 `iteration_index`（1, 2, 3...）并如实记录；
- 若执行的是为本题现场编写的专属求解/验证脚本，必须在获得 `artifact_id` 后立即调用 `physics-agent/hooks/runlog.py`，将**中文物理说明 + 脚本完整源码 + 命令行调用 + 完整回显日志**写入 `physics-agent/runtime/<task-slug>/runlogs/<artifact_id>.txt`。

---

## 5. 核心数值结论可追溯锚定 (Traceability Anchor)

在最终汇报给出的所有核心数值、极值或理论临界点，必须在 `problem_state.json` 的 `report.traceability` 字段中显式锚定到产生该数据的具体 `artifact_id`，实现从论文图文直接穿透查验原始运行日志。
