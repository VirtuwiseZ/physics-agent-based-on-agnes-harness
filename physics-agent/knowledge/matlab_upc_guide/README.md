# UPC 物理竞赛 MATLAB R2023b 建模仿真知识库与选手作战手册
# (UPC Physics Competition MATLAB Modeling & Simulation Handbook)

> **文档属性**：UPC 48小时竞赛实战仿真总指挥手册、AI 破题决策路由表、MATLAB R2023b 算法武器库  
> **制定基线**：基于 2010–2025 年 16 届 UPC 真题题型分析与 74 篇特等奖/金牌（Gold Medal）论文实证  
> **适用对象**：
> 1. **人类参赛选手**：48小时极速破题、建模仿真、图表生成与论文写作的案头作战手册；
> 2. **AI 智能体 / DSH Copilot**：接收赛题后快速识别物理对象、映射数学方程类型、推荐求解器与匹配代码模版的核心决策指南。

---

## 一、 竞赛协同核心原则与 48 小时作战节奏

### 1. 人机协同边界（黄金分工法则）
- **人类选手主导主权（The Commander）**：
  - 把握物理主导机理、关键合理假设与建模取舍；
  - 在 Microsoft Word (`.docx`) 中主导撰写学术论文正文，推敲学术逻辑；
  - 在 MATLAB 交互界面中旋转、微调 3D 轨迹与云图，选定最优视角复制/导出终图。
- **AI 助手充当计算副驾与学术顾问（The Co-pilot & Reviewer）**：
  - **赛题第一性解构**：提取核心作用力、无量纲特征数与特征时间/尺度；
  - **方程降阶与符号展开**：将二阶动力学方程规范转化为一阶状态空间形式；
  - **提供模块化高精度 MATLAB 脚本**：调用经过金牌实证的代码模版，避免低级语法与数值错误；
  - **学术审阅与调试**：排查 MATLAB 报错、视觉审阅导出图表合理性、审查 Word 过程草稿中的物理严密性。

### 2. 48 小时时间切分作战节奏表
```
[T+00h ~ T+03h: 破题与路线确立]
  • 查阅本文档【第二节 决策路由表】，对赛题分类；
  • 完成费米数量级估算，确定主导效应（保留）与微扰项（忽略）；
  • 确立两套模型演进：V0.1 最简基线解析模型 + V1.0 高保真数值仿真模型。

[T+03h ~ T+20h: MATLAB 建模仿真与数值求解（攻坚核心）]
  • 选用【第三节】对应的代码模版，填入题目具体参数与环境子模型；
  • 运行 forward simulation，用事件函数（Events）截断边界；
  • 运行逆向打靶法（fzero/fsolve）求出核心未知量；
  • 执行全域参数扫描（meshgrid），绘制 2D/3D 学术科研图表。

[T+20h ~ T+44h: Word 论文撰写与数据回填]
  • 人类在 Word 模板中组织八大学术章节（Abstract, Assumptions, Model, Results, Discussion）；
  • DSH 读取论文草稿，进行学术同行评审（Peer Review），挑出量纲不平衡或物理漏洞。

[T+44h ~ T+48h: 极限自洽检验与终稿封包]
  • 验证退化极限（如阻力为0时退化为经典抛物线）；
  • 检查图表字体与物理单位，导出正式 PDF 并核验提交。
```

---

## 二、 物理题目分类与 MATLAB 算法决策全景表 (AI 破题路由表)

当输入赛题给 AI 或选手自主破题时，立即对照下表完成物理机理到算法工具的精准映射：

| 题目物理板块 | 典型关键词与赛题特征 | 物理主导效应与关键控制方程 | MATLAB 推荐算法与求解器 | 知识库匹配模版 / 文件 |
| :--- | :--- | :--- | :--- | :--- |
| **大气弹道与高速气动力学** | 火炮(2025B)、跳伞(2023A)、足球(2022B)、水弹(2014B)、乒乓球(2012B) | • 变密度大气 $\rho(z)$<br>• 跨音速阻力危机 $C_D(M, Re)$<br>• 马格努斯效应 $\vec{\omega}\times\vec{v}$<br>• 三维风场矢量扰动 | • **`ode113` / `ode45`** 高阶积分<br>• **`odeset('Events')`** 落地点/触地截断<br>• **`fzero`** 打靶法反求射角/初速 | `02_battle_tested_templates/`<br>[`template_ballistics_shooting.m`](02_battle_tested_templates/template_ballistics_shooting.m) |
| **天体引力与连续推力轨道** | 土星推进(2020A)、小行星撞击/偏转(2022A/2021B)、光帆(2018A)、木星引力弹弓(2013A) | • 万有引力与多体引力场<br>• 齐奥尔科夫斯基变质量方程 $\dot{m}=-T/(I_{sp}g_0)$<br>• 轨道能量与角动量守恒 | • **`ode113`**（设置 `RelTol: 1e-9`）<br>• 守恒量数值漂移检验<br>• 开普勒轨道与打靶变轨 | `02_battle_tested_templates/`<br>[`template_orbital_continuous.m`](02_battle_tested_templates/template_orbital_continuous.m) |
| **多阶段动力学与瞬态事件** | 太空跳伞多级开伞(2023A)、蹦床跳跃(2023B)、投石机释放(2010B)、篮球碰撞(2011B) | • 系统方程在特定时刻发生离散跃迁<br>• 碰撞能量恢复系数 $e$<br>• 人体过载极限加速度 $a_{max}$ | • 多级链式 **`ode45`**<br>• 状态连续性继承：$y_{0, k+1} = y_{end, k}$<br>• 阶跃事件函数阵列 | `02_battle_tested_templates/`<br>[`template_multistage_events.m`](02_battle_tested_templates/template_multistage_events.m) |
| **瞬态传导与气体扩散** | 空间站小孔漏气(2024A)、火星大气演化(2021A)、堆肥堆导热(2018B)、行星地热(2012A) | • 傅里叶导热偏微分方程 (PDE)<br>• 连续性方程与稀薄气体出流<br>• 空间半离散化导热方程 | • **`pdepe`**（一维瞬态偏微分方程）<br>• 空间半离散化（MOL）+ **`ode15s`**<br>• 3D时空演化瀑布曲面 | `02_battle_tested_templates/`<br>[`template_pde_heat_diffusion.m`](02_battle_tested_templates/template_pde_heat_diffusion.m) |
| **耦合振动与声学共振** | Sasando乐器(2025A)、蹦床多刚体弹跳(2023B)、浅水重力波(2021B) | • 多自由度质量-阻尼-刚度矩阵 $M\ddot{x}+C\dot{x}+Kx=F$<br>• 亥姆霍兹共鸣腔方程<br>• 稳态受迫振动与主振型 | • **`eig`** 模态频率与振型分解<br>• **`ode45`** 状态空间受迫时域积分<br>• **`fft`** 稳态离散傅里叶频域提取 | `02_battle_tested_templates/`<br>[`template_vibration_acoustics.m`](02_battle_tested_templates/template_vibration_acoustics.m) |
| **参数敏感性扫描与全域相图** | “评估不同风速/高度的影响”、“寻找最佳策略”、“参数容差范围” | • 双参数/多参数全空间遍历<br>• 临界相变与可行域边界提取 | • **`meshgrid`** 网格矩阵构建<br>• **`tiledlayout` + `contourf`** 等高线<br>• **`exportgraphics`** 导出 300 DPI | `02_battle_tested_templates/`<br>[`template_param_sweep_heatmap.m`](02_battle_tested_templates/template_param_sweep_heatmap.m) |
| **环境扰动与不确定性分析** | 真实风场脉动(2020B)、守门员防守概率(2022B)、分子碰撞扩散(2014B/2021A) | • 初始参数高斯扰动 $\mathcal{N}(\mu, \sigma^2)$<br>• 随机风场湍流谱<br>• 落点散布椭圆与命中概率 | • **`randn` / `rand`** 蒙特卡洛批量仿真<br>• 95% 置信椭圆（CEP）提取<br>• 统计直方图与核密度估计 | `02_battle_tested_templates/`<br>[`template_monte_carlo.m`](02_battle_tested_templates/template_monte_carlo.m) |

---

## 三、 金牌范文提炼的“仿真五大防线”（模型质量红线）

无论 AI 输出代码还是人类选手搭建模型，必须对照以下五条红线执行自检，这是确保论文进入金牌档位的关键：

1. **防线 1：环境机理真实性（杜绝常数物理场）**
   - 严禁将大气密度视为恒定 $1.225\text{ kg/m}^3$；在超过数百米的高空，必须采用国际标准大气模型（ISA）分层计算温度、气压与密度；
   - 严禁忽略流体粘度随温度的变化；必须采用萨瑟兰公式（Sutherland's Formula）修正动力粘度 $\mu(T)$。
2. **防线 2：无量纲数与机制判断（特征尺度先行）**
   - 在写下任何流体力学/阻力公式前，必须先计算马赫数 $M = v / c_s$ 和雷诺数 $Re = \rho v d / \mu$；
   - 明确指出当前流动是处于斯托克斯阻力区（$F \propto v$）、牛顿平方阻力区（$F \propto v^2$）、还是跨音速激波剧增区（Drag Crisis）。
3. **防线 3：终止边界确定性（必须有事件截断）**
   - 严禁在仿真中使用固定的 $t_{end}$ 硬编码猜测物体落地时刻；
   - 必须通过 `odeset('Events', @event_func)` 依靠零点交叉物理检测（如高度 $y=0$ 且 $\dot{y}<0$）精确截断。
4. **防线 4：逆向求解严密性（自动化打靶求根）**
   - 针对“求发射仰角”、“求最小质量”等赛题核心问，必须通过 `fzero` 或 `fminbnd` 给出精确到小数点后数位的最优数值解；
   - 严禁通过肉眼在图表上手动挑选折线最低点敷衍交卷。
5. **防线 5：极端退化极限自洽（Asymptotic Consistency）**
   - 复杂模型必须能够在特定参数趋于极限时退化为经典物理公理；
   - 例如：当空气阻力系数 $C_D \to 0$ 时，弹道轨迹必须精确重合于初等物理的真空抛物线解析公式 $R = \frac{v_0^2 \sin 2\theta}{g}$。

---

## 四、 本知识库详细资产导航与使用方法

- **[01_solver_matrix.md](01_solver_matrix.md)**：MATLAB 求解器深度矩阵。详细对比 `ode45`、`ode113`、`ode15s` 的数值步长控制、精度容差 (`RelTol`/`AbsTol`) 与刚性判定。
- **[02_battle_tested_templates/](02_battle_tested_templates/)**：七套即插即用的金牌级实战 `.m` 脚本：
  1. `template_ballistics_shooting.m`：三维外弹道 + 变密度大气 + 跨音速激波 + 打靶法反求；
  2. `template_multistage_events.m`：多阶段物理演化 + 事件函数阵列 + 状态连续继承；
  3. `template_orbital_continuous.m`：连续小推力变轨 + 变质量火箭方程 + 机械能/角动量守恒校验；
  4. `template_param_sweep_heatmap.m`：双参网格扫描 + `tiledlayout` 现代排版 + 等高线与可行域相图；
  5. `template_monte_carlo.m`：高斯扰动随机风场 + 散布椭圆 + 命中概率直方图；
  6. `template_pde_heat_diffusion.m`：一维瞬态偏微分方程 (`pdepe`) + 3D 时空温度分布瀑布图；
  7. `template_vibration_acoustics.m`：多自由度耦合振动模态分解 (`eig`) + 受迫振动时域积分 + FFT 频谱分析。
- **[03_physics_submodels.md](03_physics_submodels.md)**：高频物理底层子函数代码速查（ISA大气、萨瑟兰粘度、跨音速阻力曲线、马格努斯力、万有引力场、小孔出流）。
- **[04_modern_matlab_style_guide.md](04_modern_matlab_style_guide.md)**：现代 MATLAB R2023b 规范与避坑指南（点乘点除防坑、匿名函数句柄传参、报错急救）。
- **[05_paper_figure_recipes.md](05_paper_figure_recipes.md)**：专为 UPC 竞赛定制的学术级出图秘籍（双 Y 轴排版、LaTeX 字体解析、`exportgraphics` 300 DPI 无损导出）。

---

## 五、 数据源与实测参数获取（网络检索资源的转化）

在 48 小时极速竞赛中，模型不仅需要数学方程，更需要真实、高信度的物理参数支撑（详见 [`物理竞赛与仿真数据源权威指引.md`](../物理竞赛与仿真数据源权威指引.md)）。以下是快速导入 MATLAB 的规范：

1. **基础物理常数**：直接读取内置权威数据集 [`reference_data/nist_codata2022_constants.txt`](../reference_data/nist_codata2022_constants.txt)，确保引力常数 $G$、阿伏伽德罗常数 $N_A$、玻尔兹曼常数 $k_B$ 与光速 $c$ 具备学术权威出处。
2. **天体物理与轨道数据**：
   - 太阳系天体质量、半径与轨道根数：直接查询并读取 [`reference_data/nasa_exoplanets_mass_radius.csv`](../reference_data/nasa_exoplanets_mass_radius.csv) 或通过 NASA Horizons REST API 获取精确星历；
   - MATLAB 内置读取：`readtable('physics-agent/knowledge/reference_data/nasa_exoplanets_mass_radius.csv')`。
3. **真实环境气象与标准大气**：
   - 海拔 0~80 km 范围内的大气参数统一采用 `03_physics_submodels.md` 中的 `isa_atmosphere(H)` 函数，严禁人工编造密度常数。
4. **物性拟合参数**：
   - 气体比热容与蒸气压从 NIST Chemistry WebBook 提取 Shomate 系数，在 MATLAB 中使用多项式 `polyval` 快速求解。

---

## 六、 人机协作标准交互提问模版（Prompting Recipes for Contestants）

在 48 小时比赛中，为了让 AI 迅速理解题目并生成最规范的代码，人类选手推荐使用以下标准 Prompt 结构向 AI 发起请求：

### 模版 1：请求初版动力学建模与代码骨架
```text
【赛题】: [粘贴题目文本]
【物理对象与机制】: 研究对象为 [xxx]，主要受力包括 [重力、变密度阻力、风场...]，次要微扰 [xxx] 忽略。
【目标任务】: 
  1. 建立一阶状态空间 ODE 方程；
  2. 匹配 knowledge/matlab_upc_guide/ 中的模版 [如 template_ballistics_shooting.m]；
  3. 编写完整的 MATLAB R2023b 脚本，包含落地事件截断与 300 DPI 导出图。
```

### 模版 2：请求逆向打靶或全域敏感性分析
```text
【当前状态】: 我们已经跑通了前向仿真模型 [粘贴或指明代码]。
【目标任务】: 
  1. 利用 fzero / fmincon 编写逆向打靶外层循环，反求击中目标 [距离/质量/时间] 的最优参数；
  2. 在参数 [范围 A] 和 [范围 B] 的二维网格上进行 meshgrid 扫描；
  3. 绘制带有等高线注记与最大值脊线的双联科研云图 (参考 05_paper_figure_recipes.md)。
```

### 模版 3：代码报错或结果异常排查
```text
【运行报错】: [粘贴 MATLAB 报错信息，如 Failure at t=... 或 Matrix dimensions must agree]
【当前脚本】: [粘贴报错脚本的关键段落]
【诊断要求】: 对照 04_modern_matlab_style_guide.md 检查：是否存在隐式 global 污染？是否有除零或负数开方？是否存在未点乘 (.*) 导致的维度错误？请给出修正后的代码。
```

