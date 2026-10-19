---
name: physics-defense-lines
description: '三道确定性物理工程防线：进入数值求解与结论输出前，强制运行符号量纲齐次性门禁（SymPy+Pint）、物理极限与边界门禁（极端退化与单调性扫描）、以及配额退火回滚机制。'
---

### Three Deterministic Defense Lines (Do Not Bypass)

大语言模型基于概率生成文本，缺乏物理公理与符号计算引擎，容易产生虚假非物理数值或量纲不平衡。
在进入数值计算与最终结论交付前，**必须通过外部真实运行以下确定性程序化防线**，杜绝口算或伪造检验：

- **`pwsh` 工具调用规范**：统一使用顶层扁平属性 `command: "..."` 与 `description: "..."`（5–10 词主动语态说明），严禁使用 `input` 嵌套。

---

## 1. 符号量纲齐次性门禁 (Dimensional Gate)

在写下物理控制方程或理论解后，**必须在任何数值代入之前**调用 `physics-agent/hooks/dimensional_gate.py`：
- **核心机制**：通过 SymPy 解析方程语法树，利用 Pint 物理单位体系严格核验等式两侧的基本物理量纲（$[M],[L],[T],[I],[\Theta]$）是否严格配平；
- **微分方程写法规则**：若控制方程含有导数项（如 $dv/dt$），在 `--equation` 中必须写为 SymPy 显式函数 `Derivative(v(t), t)`，并在 `--dims` 中分别声明自变量与因变量的量纲，严禁手写未解析的非标字符串；
- **硬拦截原则**：量纲检查失败（FAIL）时，必须立即停下排查物理公式的推导错误，严禁私自绕过量纲门进入后续计算。

```powershell
python physics-agent/hooks/dimensional_gate.py --equation "F - m * Derivative(v(t), t)" --dims "F:N, m:kg, v:m/s, t:s"
```

---

## 2. 物理边界与退化极限门禁 (Boundary Gate)

在得出数值模型或闭合解析解后，调用 `physics-agent/hooks/boundary_gate.py` 运行极限情况检验：
- **极端物理退化极限检验**：
  - 引力助推模型：当卫星质量 $M \to 0$ 时，探测器减速/偏转角必须严格收敛至 0；
  - 空气阻力模型：当高度 $h \to \infty$（大气密度 $\rho \to 0$）时，加速度必须精确退化为真空自由落体；
  - 波动光学模型：当狭缝宽度 $a \gg \lambda$ 时，衍射中央明纹角宽度必须收敛至几何光学直线传播极限；
- **全域参数单调性与物理趋势扫描（Sweep Scan）**：
  - 扫描主导物理参数在宽泛定义域内的响应，自动检查是否存在除零发散、负绝对温度、超光速、或非物理虚假伪收敛；
- 只有通过全部边界与极限测试，流水线方可进入正式汇报阶段。

```powershell
python physics-agent/hooks/boundary_gate.py --model-script physics-agent/runtime/<task-slug>/model.py --spec physics-agent/runtime/<task-slug>/boundary_spec.json
```

---

## 3. 配额退火与假设层回滚机制 (Quota & Annealing Strategy)

- **有限重试配额**：数值求解或代码报错调试严格遵守 $N \le 3$ 次重试上限；
- **退火回滚铁律**：若连续 3 次求解发散、数值溢出或未能收敛，**禁止在底层代码中反复微调参数盲目撞运气**，必须触发退火机制：
  1. 将状态机回滚至 **假设层（Hypothesis Layer）**；
  2. 重新审视基本物理假设是否合理（例如：是否忽略了关键的激波阻力、是否把刚体当作质点导致力矩不平衡、流体雷诺数是否超出了层流假设）；
  3. 修正物理假设与控制方程后，重新执行量纲门与边界门，坚决杜绝在代码层悄悄打“非物理补丁”。
