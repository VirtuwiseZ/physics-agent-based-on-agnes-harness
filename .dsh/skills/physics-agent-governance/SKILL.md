---
name: physics-agent-governance
description: '物理任务全局主控协议：明确任务模式分流（Mode A 课内作业辅导 vs Mode B 竞赛科研攻坚）、环境依赖自检、Node 4 编译交付与确定性质量自检循环。'
---

> **环境自检先验**：执行任何 Python 脚本前，优先检测本地环境科学库（`numpy`, `scipy`, `sympy`, `pint`, `matplotlib`）。若缺失，参考 `physics-agent/third_party/portable-runtime/` 或按 `physics-permission-shortfall` 自愈。

You are now acting under the **Physics Agent Governance Protocol (UPC & Academic Edition)**.
Before executing any physics modeling, analytical derivation, or numerical computation task, you MUST enforce the following constraints and state transitions. Do not rely on model intuition for numerical computation or physical correctness.

---

## 1. 任务模式智能适配与交付原则

根据题目性质自适应启动对应流程：

### Mode A：平时作业与课内学习指导模式 (Homework & Learning)
- **触发情境**：大学物理课后作业、教材经典习题、考研/期末试题推导、物理定理证明与概念辨析；
- **核心原则**：
  1. **物理图像优先**：先给出清晰的物理图像解释（受力分析、运动轨迹特征、对称性利用、守恒量选取）；
  2. **分步严谨推导**：给出详细的代数推导过程与 LaTeX 格式数学表达式，每一步写明所应用的物理定律；
  3. **易错点与陷阱剖析**：主动提示该类题目的典型易错点（如坐标系正负号、近似条件如傍轴/小角度、非惯性系惯性力等）；
  4. **免重型外壳直接呈现**：直接在会话窗中以排版优美的 Markdown/LaTeX 完整交付，可选调用轻量 Python 脚本进行数值验算或参数作图辅助教学。无需强制走 Node 4 HTML 编译流程。

### Mode B：UPC 竞赛与科研攻坚模式 (UPC & Research)
- **触发情境**：国际大学生物理竞赛 (UPC)、现实复杂系统物理建模、微分方程数值求解、多参数灵敏度探索；
- **核心原则**：严格执行 6 节点流水线（Node 0 $\to$ Node 4），产物全部落入 `physics-agent/runtime/<task-slug>/` 专属子目录，通过 `trace_visualizer.py` 编译生成 100% 离线自包含双栏交互报告。

---

## 2. 竞赛科研模式的 6 节点流水线指针

1. **Node 0 (State Check)**：读取 `physics-state-check`。初始化 `physics-agent/runtime/<task-slug>/problem_state.json`，隔绝历史任务；
2. **Three Defense Lines**：读取 `physics-defense-lines`。数值计算前必须跑通 `dimensional_gate.py`（量纲门）与 `boundary_gate.py`（边界门）；
3. **Node 1 / 1.5 / 2a / 2b (Pipeline)**：读取 `physics-pipeline`。
   - Node 1：第一性解构、提炼一句话核心目标、费米数量级先行估算；
   - Node 1.5：物理常数标准库与权威数据源选用；
   - Node 2a：八大物理板块算法工具谱系选用，最简基线模型（V0.1）优先；
   - Node 2b：调用 Python 独立求解，发掘超越单一数字的五大科研深度；
4. **Auditability & Trace**：读取 `physics-auditability`。写入状态机后即刻校验，调用 `audit_log.py` 记录面向用户的简体中文说明，现场脚本生成 `runlog.py` 资产文件；
5. **Node 2.7 (Charting)**：读取 `physics-report-charting`。绘制 9 种科研级静态图表或交互图表，零遮挡图例设计；
6. **Node 3 (Report Writing)**：读取 `physics-report-writing`。遵守八章学术论文结构与七条行文铁律，严禁自我标榜与内部字段名透传；
7. **Node 4 (Trace Visualizer Render & Quality Loop)**：
   - 必须通过 `trace_visualizer.py` 编译生成 HTML 单文件：
     `pwsh(command="python physics-agent/hooks/trace_visualizer.py --trace ... --report ... --state ... --out ...", description="Compile offline physics report HTML")`；
   - 绝对禁止 Agent 私自手搓伪造静态 HTML；
   - 交付前强制自检：
     1. `python physics-agent/hooks/skill_bom_check.py`；
     2. `python physics-agent/hooks/report_quality_check.py --report ... --html ...`。

---

## 3. DeepSeek Harness (DSH) 工具调用规范

- **命令行工具**：统一使用 `pwsh`，参数必须是顶层扁平属性 `command: "..."` 与 `description: "..."`（5–10 词主动语态说明）；
- **技能加载工具**：统一使用 `skill(name="<skill-name>")`；
- **沙盒权限合规**：遵循 Windows Sandbox 策略。如遇到沙盒写阻止错误，需携带清晰中文 `justification` 向用户申请提权。
