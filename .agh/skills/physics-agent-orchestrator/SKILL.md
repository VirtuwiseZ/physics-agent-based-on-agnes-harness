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
| **Mode B：UPC 竞赛与科研攻坚模式**<br>*(UPC & Competition Mode)* | • 国际大学生物理竞赛 (UPC 48h)<br>• 开放性现实物理系统建模与仿真<br>• 微分方程数值求解与参数优化<br>• 参赛选手全流程破题、仿真与论文写作辅导 | • **五阶段作战节奏**（破题→V0.1基线→MATLAB仿真→Word论文→自洽封包）<br>• **论文六大固定逻辑环节**（明确问题、定义边界、建模型、求解、检验、交付答案）<br>• **MATLAB R2023b 战备模版匹配**与 300 DPI 纯英文 LaTeX 科研图表<br>• 人机协同边界：人类在 Word 中撰写论文，AI 担任计算副驾与学术同行评审 | • **MATLAB 仿真代码与 300 DPI 出图**<br>• **标准 Word 论文工程模板** (`UPC_Paper_Standard_Template.docx`)<br>• **过程同行评审报告**（查验量纲、假设自洽、极端退化极限）<br>• 可选离线交互式科研学术报告 (HTML) | 完整 6 节点流水线 + UPC 战备库：<br>1. [`upc_competition_workflow_guide.md`](../../physics-agent/knowledge/upc_competition_workflow_guide.md)<br>2. [`matlab_upc_guide/README.md`](../../physics-agent/knowledge/matlab_upc_guide/README.md)<br>3. `physics-pipeline`<br>4. `physics-defense-lines`<br>5. `physics-report-writing` |

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
