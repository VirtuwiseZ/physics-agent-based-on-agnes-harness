# MATLAB 数值求解器深度选型与调优指南 (Numerical Solver Matrix for UPC)

> **文档属性**：专为 UPC 物理竞赛高难度常微分方程（ODE）、偏微分方程（PDE）与逆向打靶优化定制的求解器工程指南  
> **归档位置**：`physics-agent/knowledge/matlab_upc_guide/01_solver_matrix.md`

---

## 一、 常微分方程组（ODE）求解器全景矩阵

在 UPC 竞赛中，90% 的物理系统最终都化归为常微分方程组。选用错误的求解器会导致：积分极其缓慢、计算步长坍缩、假发散或非物理数值耗散。

| 求解器名称 | 算法原理 | 刚性适应度 | 计算精度阶数 | 适用物理场景与赛题案例 | 核心优势与评委认可点 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`ode45`** | Runge-Kutta (Dormand-Prince 4/5) | 非刚性 (Non-stiff) | 中等 (4-5 阶自适应) | 常规抛体弹道、短时弹簧振动、非极端天体引力 | MATLAB 默认首选，单步误差控制自适应变步长，鲁棒性好。 |
| **`ode113`** | Adams-Bashforth-Moulton 多步法 | 非刚性 (Non-stiff) | 极高 (1-13 阶可变) | **长程平滑外弹道(2025B)、卫星深空轨道(2020A)、高精度飞掠(2013A)** | **金牌首选**：对于 RHS（右端函数）求值复杂、要求超高精度（`RelTol < 1e-8`）的场景，调用函数次数远少于 `ode45`。 |
| **`ode15s`** | 数值微分公式 (NDF/BDF) | **高刚性 (Stiff)** | 可变阶 (1-5 阶) | **化学反应动力学(2021A火星大气)、强阻尼非线性震荡、多时间尺度放电** | 当系统包含极快衰减与极慢演化两种悬殊时间尺度时，`ode45` 会卡死崩溃，必须使用 `ode15s`。 |
| **`ode23t`** | 梯形法则自适应自由插值 | 中度刚性 (Moderately stiff) | 低阶 (2 阶) | 无阻尼/弱阻尼机械谐振、受迫振荡无数值耗散系统 | 适合需要严格维持机械能守恒、不引入人工阻尼的振动系统。 |

---

## 二、 精度容差与步长控制调优（Tolerance Control）

金牌论文与普通论文的区别之一在于是否显式配置容差。在天体轨道与高空外弹道中，默认容差（`RelTol=1e-3`, `AbsTol=1e-6`）往往会累积严重的位置漂移。

### 1. 推荐容差配置规范
```matlab
% 1. 常规弹道与工程问题（平衡计算速度与精度）
options_standard = odeset('RelTol', 1e-6, 'AbsTol', 1e-8);

% 2. 金牌级高精度外弹道与天体深空轨道（防止长距离积分伪漂移，如 2025-GM-B-188）
options_high_precision = odeset('RelTol', 1e-9, 'AbsTol', 1e-11, ...
                                'NormControl', 'on', ...  % 按状态向量范数控制误差
                                'MaxStep', 0.5);          % 强制限制最大步长，防止错过瞬态
```

### 2. 诊断积分发散的黄金法则
若运行 ODE 求解器时 MATLAB 报错：
`Failure at t=... Unable to meet integration tolerances without reducing step size below the smallest acceptable value.`
- **排查第一步**：检查控制方程是否存在除以零奇点（如引力 $G M / r^2$ 当 $r \to 0$，或空气阻力当相对速度 $v_{rel} = 0$ 时导数不光滑）；
- **排查第二步**：系统是否呈现出强刚性？尝试将 `ode45` 替换为 `ode15s`；
- **排查第三步**：若因方程本身物理激变引起，适当将 `RelTol` 临时放宽至 `1e-4` 测试能否跑通，再排查物理根源。

---

## 三、 事件检测机制（Event Location）实战法则

物理过程往往由边界条件或离散事件决定终止时刻。使用事件函数可以让 MATLAB 在积分过程中精确插值定位零点，无需盲目猜测 $t_{end}$。

### 1. 事件函数标准语法模板
```matlab
function [value, isterminal, direction] = my_event_func(t, y)
    % value: 检测表达式，当 value == 0 时触发事件
    % isterminal: 1 表示触发后立刻终止 ode 积分；0 表示仅记录事件时间但继续积分
    % direction: 
    %    0: 任何方向穿过零点均触发
    %   +1: 仅当 value 从负变正时触发（如上升穿过特定高度）
    %   -1: 仅当 value 从正变负时触发（如下落砸向地面 y <= 0）

    altitude = y(2); % 假设 y(2) 为垂直高度 y
    value = altitude - 0; % 当高度下降到 0m 时
    isterminal = 1;       % 立刻终止仿真
    direction = -1;       % 仅当下落穿过地表时生效
end
```

### 2. 调用事件函数
```matlab
options = odeset('Events', @my_event_func, 'RelTol', 1e-8);
[t, y, te, ye, ie] = ode45(@(t,y) odefun(t,y), [0, 1000], y0, options);

% 返回值解释：
% te: 事件发生的精确时刻
% ye: 事件发生时的精确状态向量 [x, y, vx, vy...]
% ie: 触发了哪个事件（多事件函数时有效）
```

---

## 四、 逆向打靶法与根寻优（Shooting Methods）

赛题中经常要求“求最佳发射仰角以击中 1200m 目标”或“求使飞船入轨的最小燃料”。

### 1. 单变量打靶法（`fzero`）
```matlab
function optimal_theta = solve_shooting_angle(v0, target_x)
    % 目标函数：在给定发射角 theta 下，计算射程与目标距离的残差
    obj_fun = @(theta_deg) forward_trajectory_residual(theta_deg, v0, target_x);

    % 在 [10度, 80度] 区间内寻找使残差为 0 的发射角
    theta_bracket = [10, 80];
    options = optimset('TolX', 1e-8, 'Display', 'off');
    optimal_theta = fzero(obj_fun, theta_bracket, options);
end

function residual = forward_trajectory_residual(theta_deg, v0, target_x)
    theta_rad = deg2rad(theta_deg);
    y0 = [0; 0; v0 * cos(theta_rad); v0 * sin(theta_rad)];
    
    opts = odeset('Events', @ground_hit_event);
    [~, y_sol, ~, ye, ~] = ode45(@dynamics_ode, [0, 500], y0, opts);
    
    x_impact = ye(1); % 落地时的水平距离
    residual = x_impact - target_x; % 残差 = 实际落地距离 - 目标距离
end
```

### 2. 多参数带约束极值优化（`fmincon`）
当需要同时优化多个变量（如初速 $v_0$、仰角 $\theta$、自旋角速度 $\omega$）以达到最大射程且过载不超过人体极限时：
```matlab
% 变量向量: p = [v0, theta_deg, omega]
p0 = [300, 45, 10];
lb = [100, 5, 0];    % 下界
ub = [450, 85, 50];  % 上界

options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp');
p_opt = fmincon(@(p) -calculate_range(p), p0, [], [], [], [], lb, ub, @nonlinear_constraints, options);
```

---

## 五、 偏微分方程（PDE）一维瞬态求解（`pdepe`）

当遇到一维热传导（如 2018-B 堆肥堆散热、2012-A 超级地球地热传导）或薄膜一维波动时，使用 MATLAB 内置的 `pdepe`：
方程标准形式：
$$c\left(x,t,u,\frac{\partial u}{\partial x}\right) \frac{\partial u}{\partial t} = x^{-m} \frac{\partial}{\partial x}\left(x^m f\left(x,t,u,\frac{\partial u}{\partial x}\right)\right) + s\left(x,t,u,\frac{\partial u}{\partial x}\right)$$
- $m=0$：平面直角坐标系；
- $m=1$：圆柱对称柱坐标系；
- $m=2$：球面对称球坐标系。
在 `pdepe` 中仅需定义三个简短子函数（PDE 方程系数 `pdefun`、初始条件 `icfun`、边界条件 `bcfun`），即可在极短时间内得到时空热力分布网格 $u(x, t)$。
