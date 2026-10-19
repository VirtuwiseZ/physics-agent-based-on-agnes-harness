---
name: physics-agent-orchestrator
description: '物理题的双模式分流与流水线路由器：收到任何物理习题、课内作业指导、理论推导、大学物理概念阐释、或者 UPC 等物理竞赛建模与数值分析任务时，先读本 Skill 判断进入哪种模式（Mode A 课内作业辅导 vs Mode B 竞赛科研攻坚），并按需调用 skill 加载对应子 Skill。'
---

# Physics Agent 双模式分流与子 Skill 路由表

收到任何物理分析、课内作业、理论推导、概念教学阐释、数值求解或竞赛建模任务时，严禁凭直觉自由跳步或口算数值。请先通过 `skill(name="...")` 读取对应规则。

---

## 一、 双任务模式智能分流（Dual-Mode Routing）

根据用户的任务性质与提问意图，自动匹配最佳解题路径：

| 任务模式 | 典型场景 | 核心关注点 | 交付形态 | 推荐子 Skill 链路 |
| :--- | :--- | :--- | :--- | :--- |
| **Mode A：平时作业与课内学习指导模式**<br>*(Homework & Learning Mode)* | • 大学物理教材课后习题<br>• 期末/考研物理典型真题<br>• 定理证明与分步解析推导<br>• 概念混淆辨析与易错点剖析 | • 物理图像与受力/场图阐释<br>• 严谨清晰的逐步代数推导<br>• 揭示解题思路与常见思维陷阱<br>• 提供独立边界检验与验算 | • **直接在会话窗优雅呈现**<br>• 标准 LaTeX 规范数学公式<br>• 重点步骤物理依据明晰<br>• 可选轻量 Python 仿真验算 | 1. `physics-pipeline`<br>2. `physics-defense-lines`（选）<br>3. `physics-report-writing`（作业辅导规范） |
| **Mode B：UPC 竞赛与科研攻坚模式**<br>*(UPC & Competition Mode)* | • 国际大学生物理竞赛 (UPC)<br>• 开放性复杂现实物理系统建模<br>• 现实多因素耦合与微分方程组求解<br>• 参数敏感性与无量纲场分析 | • 第一性原理拆解与目标提炼<br>• 费米数量级先行估算<br>• 最简基线模型（V0.1）优先<br>• 确定性三道物理防线拦截<br>• 超越单一数字的五大科研深度 | • **离线交互式科研学术报告**<br>• 100% 离线自包含单文件 HTML<br>• 八章标准学术论文结构<br>• 外挂胶囊图例矢量科学图表<br>• 毫秒级时序可穿透审计账本 | 完整 6 节点流水线：<br>1. `physics-agent-governance`<br>2. `physics-state-check`<br>3. `physics-pipeline`<br>4. `physics-defense-lines`<br>5. `physics-auditability`<br>6. `physics-report-charting`<br>7. `physics-report-writing` |

---

## 二、 1 主控 + 8 专业子 Skill 路由清单

在对应阶段前按需调用 `skill(name="...")` 加载具体子 Skill：

1. **全局主控协议与交付闭环**：`physics-agent-governance`
   - 全局生命周期治理协议、环境防线、以及 Node 4 质量自检循环；
2. **Node 0 任务专属状态机与环境初始化**：`physics-state-check`
   - 在 `physics-agent/runtime/<task-slug>/problem_state.json` 中初始化状态真源，隔绝不同题目上下文；
3. **确定性三道物理防线（量纲门 / 边界门 / 配额退火）**：`physics-defense-lines`
   - 杜绝大模型数值幻觉与量纲错误，强制运行 `dimensional_gate.py` 与 `boundary_gate.py`；
4. **核心物理建模、算法求解与多维验证流水线**：`physics-pipeline`
   - 涵盖第一性问题拆解、费米数量级先行估算、权威物理常数选用、八大物理板块算法工具谱系、以及超越单一数字的五大物理研究深度；
5. **审计留痕与运行记录资产**：`physics-auditability`
   - 单一状态真源写回校验、调用 `audit_log.py` 记录简体中文说明、现场脚本运行记录 `runlog.py` 生成；
6. **科学结果绘图与公式/图表内联**：`physics-report-charting`
   - 涵盖 9 种科研级静态图表（曲线、散点、柱状、热力场、3D 轨迹/曲面等）与交互图表，零遮挡图例设计；
7. **科学汇报撰写与教学推导组织**：`physics-report-writing`
   - 支持课内作业分步解答行文规范，以及科研学术报告八章标准结构与七条行文铁律；
8. **环境缺口与便携运行时自愈**：`physics-permission-shortfall`
   - 遇到 Windows Sandbox 权限限制或环境依赖缺失时的自愈与标准提权流程；
9. **外部文档解析（PDF/扫描件/DOCX）**：`physics-doc-parsing`
   - 仅当用户明确要求“参考某个文件/文档”时按需加载。
