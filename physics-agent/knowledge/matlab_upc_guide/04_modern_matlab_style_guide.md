# MATLAB R2023b 现代编程规范与避坑手册 (Style & Debugging Guide)

> **文档属性**：专为 UPC 竞赛物理仿真制定的代码健壮性规范、现代语法指南与常见报错急救清单  
> **归档位置**：`physics-agent/knowledge/matlab_upc_guide/04_modern_matlab_style_guide.md`

---

## 一、 现代 MATLAB R2023b 核心编码规范

### 1. 变量传递铁律：坚决杜绝 `global`，统一使用匿名函数句柄
在传统旧代码中，常通过 `global param1 param2` 向 ODE 函数传递参数。这在并行计算（`parfor`）、多目标寻优或批量扫描时会引发极难排查的全局变量竞争污染与覆盖。

- **错误写法（严禁使用）**：
  ```matlab
  global g rho Cd A % 极度危险！易受全局同名变量覆盖
  [t, y] = ode45(@ballistics_rhs, [0 100], y0);
  ```
- **现代标准写法（推荐）**：
  ```matlab
  params.g = 9.81;
  params.rho = 1.225;
  params.Cd = 0.45;
  % 将参数结构体以闭包形式安全注入句柄
  [t, y] = ode45(@(t,y) ballistics_rhs(t, y, params), [0 100], y0);
  ```

### 2. 向量化与点乘点除铁律（防范维度灾难）
在定义物理代数表达式（如动能、阻力、引力势能、温度分布）时，**必须默认采用元素级点运算（Element-wise Operations）**：
- 乘法用 `.*`，除法用 `./`，幂次用 `.^`；
- 避免直接写 `*`、`/`、`^`，否则在后续进行矩阵网格扫描（`meshgrid`）或数组一次性绘图时，MATLAB 会抛出致命的 `Matrix dimensions must agree` 或执行低效且非预期的矩阵乘法。

```matlab
% 正确规范: 对向量或网格数组直接生效
E_k = 0.5 .* m .* (vx.^2 + vy.^2);
F_d = 0.5 .* rho .* A .* Cd .* v .* vx;
```

### 3. 本地函数组织规范（Local Functions in Scripts）
自 MATLAB R2016b 起，脚本文件（`.m`）可以直接在其末尾定义局部函数（Local Functions），无需像早期版本那样为每个小函数新建独立的 `.m` 文件。
- **结构规范**：
  ```text
  myscript.m
  ├── 1. clear; clc; close all;
  ├── 2. 参数结构体定义 (params.xxx)
  ├── 3. 主求解流程 (ode45 / fzero / meshgrid)
  ├── 4. 数据统计与 figure 出图
  └── 5. 脚本末尾的本地子函数 (function dy = odefun(t,y,p)...)
  ```

---

## 二、 现代出图规范：从 `subplot` 到 `tiledlayout`

在旧版 MATLAB 中使用的 `subplot` 存在严重的坐标轴标签互相挤压、子图与标题重叠、多图共享色条布局失调等顽疾。

### 现代 `tiledlayout` 核心优势与标准代码模板
```matlab
fig = figure('Color', 'w', 'Position', [100, 100, 1050, 480]);
% 创建 1 行 2 列的平铺布局，设置边距为紧凑 (compact)
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 绘制子图 1
nexttile(1);
plot(x1, y1, 'b-', 'LineWidth', 2.0);
xlabel('距离 (m)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('高度 (m)', 'Interpreter', 'latex', 'FontSize', 11);
title('空间轨迹剖面', 'Interpreter', 'latex', 'FontSize', 12);
grid on; box on;

% 绘制子图 2
nexttile(2);
plot(t, v, 'r--', 'LineWidth', 2.0);
xlabel('时间 (s)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('速率 (m/s)', 'Interpreter', 'latex', 'FontSize', 11);
title('速度时序演化', 'Interpreter', 'latex', 'FontSize', 12);
grid on; box on;

% 添加全局大标题 (跨子图居中)
title(tiled, '拿破仑火炮外弹道多维综合响应特性', 'Interpreter', 'latex', 'FontSize', 14);
```

---

## 三、 竞赛现场 MATLAB 常见报错急救清单 (Top 5 Troubleshooting)

### 1. 报错：`Matrix dimensions must agree` 或 `Array indices must be positive integers`
- **高发诱因**：
  - 表达式漏写点乘（如写了 `v^2` 而不是 `v.^2`）；
  - 状态向量初值行向量与列向量混淆（如 ODE 初始条件要求为列向量，却传了行向量 `[1, 2, 3]`）；
- **急救方案**：
  - 检查初值：确保传给 ODE 的是列向量 `y0 = [x; y; vx; vy]`（分号隔开）；
  - 检查函数输出：确保 ODE 返回的也是列向量 `dy = [dx; dy; dvx; dvy]`。

### 2. 报错：`Failure at t=... Unable to meet integration tolerances`
- **高发诱因**：
  - 步长坍缩到机器精度下限。通常由物理除零（如天体距离 $r=0$）或强刚性震荡触发；
- **急救方案**：
  - 在除数分母处加极小防除零平滑项：`r = sqrt(x^2 + y^2 + 1e-12)`；
  - 检查相对速度模长：`v = max(norm(v_vec), 1e-6)`；
  - 更换为刚性求解器：将 `ode45` 改为 `ode15s`。

### 3. 现象：仿真跑通了，但解出来的结果全是 `NaN` 或 `Inf`
- **高发诱因**：
  - 负数开方（如速度平方由于减速算出了微弱负数 `-1e-15`，`sqrt(-1e-15)` 产生了复数，导致下游全盘 NaN）；
- **急救方案**：
  - 强制截断保护：`v = sqrt(max(vx^2 + vy^2, 0.0))`；
  - 对高度、气压等物理非负量执行保护：`h_clamped = max(h, 0.0)`。

### 4. 报错：`fzero` 报 `Function values at interval endpoints must be of opposite signs`
- **高发诱因**：
  - 打靶法搜索区间 `[a, b]` 内端点函数值同号（例如目标距离超出了最大射程，不论仰角多大都打不到，导致残差全为负）；
- **急救方案**：
  - 先用粗步长（如 `theta = 10:5:80`）跑一次前向遍历，绘制残差曲线，人工确认零点是否存在，再收紧 `fzero` 的区间 `[a, b]`；
  - 若超出物理极限，在论文中明确写出“该射程超出火炮在给定初速下的最大有效射程，属于物理不可达域”。

### 5. 现象：导出的图片文字模糊、图例被遮挡
- **高发诱因**：
  - 使用了已淘汰的 `saveas(gcf, 'fig.png')` 或截图软件；
- **急救方案**：
  - 统一使用 `exportgraphics(gcf, 'figure_name.png', 'Resolution', 300)`；
  - 图例使用外置或空旷角：`legend('Location', 'northeast', 'Interpreter', 'latex')`。


---

## 四、 面向人类选手的代码注释与编辑器交互规范 (Human-Centric Scripting & Editor Workflow)

为了最大化提升竞赛中“AI 算法副驾”与“人类程序手/建模手”的协同效率，AI 生成的所有 MATLAB 脚本必须遵循以下人类友好型交互与注释标准：

### 1. 顺带唤起编辑器与多标签页联动 (Auto Open in Editor Tab)
每次编写或更新核心仿真脚本（如 `solve_ballistics.m`）后，通过系统命令行通知 MATLAB 桌面主实例打开该文件：
- 在脚本生成后，顺带执行 `edit('solve_ballistics.m')`；
- **效果**：程序手桌面的 MATLAB Editor 会像浏览器开新标签页一样，自动新建并聚焦高亮当前代码文件，程序手无需在文件夹中翻找。
- **运行隔离铁律**：脚本头部必须使用 `clearvars; clc;`，杜绝多标签页连续运行时的全局变量串味。

### 2. 面向人类的代码结构化注释规范 (Human-Facing Commenting)
竞赛中程序手需要快速读懂代码、修改关键参数、设置断点单步调试。AI 编写的代码必须杜绝大段无注释代码块，严格执行以下“四段式”中文导读注释：

1. **头部导读卡片**：
   - 用 3~5 行清晰写明：**本脚本物理课题、对应论文哪一小节/哪一问、输入输出核心指标**。
2. **显式划定“参数调优区”（方便程序手直接上手改）**：
   ```matlab
   %% =========================================================================
   %% 1. 可调节物理参数与环境常量 (选手请在此处微调参数)
   %% =========================================================================
   m = 5.0;            % [kg] 抛体质量 (改变此值观察惯性影响)
   v0 = 350.0;         % [m/s] 初始发射速率 (跨音速区间 300~450 m/s)
   theta_deg = 35.0;   % [deg] 发射仰角 (可在此尝试 20~60 deg)
   Cd_sub = 0.20;      % [-] 亚音速阻力系数
   ```
3. **关键公式与物理定律标注**：
   - 在 ODE 状态方程或数值离散前，写明对应物理定律与微观机理，例如：
     `% 由牛顿第二定律 m*dv/dt = F_gravity + F_drag + F_magnus 展开各分量`；
     `% 萨瑟兰公式修正高空动力粘度: mu(T) = mu0 * (T/T0)^1.5 * (T0 + S)/(T + S)`。
4. **调试断点建议与取值预期（Debug Hints）**：
   - 在关键循环、打靶求根或状态突变处给出直白的预期提示，例如：
     `% [调试提示]: 若在此处打断点，残差 res 正常应在 [-50, +50] 之间，若出现 NaN 请检查初速是否过小`。
