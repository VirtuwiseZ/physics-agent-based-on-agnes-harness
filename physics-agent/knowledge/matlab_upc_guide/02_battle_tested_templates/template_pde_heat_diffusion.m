%% template_pde_heat_diffusion.m - 一维瞬态偏微分方程 (PDE) 求解模版
% 适用题材：空间站气体扩散泄压(2024A)、堆肥堆瞬态热传导(2018B)、行星地幔冷却(2012A)
% 核心技术：MATLAB 内置 pdepe 求解器 (抛物型与双曲型方程) + 时空离散网格 + 3D瀑布曲面图与截面时序图
% 编写环境：MATLAB R2023b 及以上

clear; clc; close all;

%% 1. 物理参数定义 (以一维非稳态导热与热耗散为例)
p.k_thermal = 0.85;       % 导热系数 (W/(m*K))
p.rho       = 1600.0;     % 介质密度 (kg/m^3)
p.cp        = 1200.0;     % 质量比热容 (J/(kg*K))
p.alpha     = p.k_thermal / (p.rho * p.cp); % 热扩散率 alpha (m^2/s)
p.h_conv    = 15.0;       % 边界对流换热系数 (W/(m^2*K))
p.T_ambient = 293.15;     % 环境对流温度 (20 degC = 293.15 K)
p.T_init    = 353.15;     % 初始核心高温 (80 degC = 353.15 K)
p.L_total   = 1.0;        % 空间总长度 (m)

fprintf('====================================================\n');
fprintf('  UPC 一维瞬态偏微分方程求解器 (pdepe Transient PDE)\n');
fprintf('  介质热扩散率 alpha: %.4e m^2/s\n', p.alpha);
fprintf('  空间域: [0, %.2f] m | 初始温度: %.2f K | 环境温度: %.2f K\n', p.L_total, p.T_init, p.T_ambient);
fprintf('====================================================\n\n');

%% 2. 时空网格构建
% 空间网格 x (从中心 0 到边界 L_total)
m_coord = 0; % 几何对称性: 0 为平板直角坐标, 1 为圆柱对称, 2 为球对称
x_mesh = linspace(0, p.L_total, 60);

% 时间网格 t (演化 24 小时 = 86400 秒)
t_mesh = linspace(0, 86400, 100);

%% 3. 调用 pdepe 求解偏微分方程
fprintf('[Step 1] 正在调用 pdepe 执行时空偏微分方程积分...\n');

% 求解格式: sol = pdepe(m, pdefun, icfun, bcfun, xmesh, tspan)
sol = pdepe(m_coord, @(x,t,u,dudx) pde_equation(x,t,u,dudx,p), ...
                     @(x) pde_initial(x, p), ...
                     @(xl,ul,xr,ur,t) pde_boundary(xl,ul,xr,ur,t,p), ...
                     x_mesh, t_mesh);

% sol 矩阵维度: [length(t_mesh) x length(x_mesh)]
T_solution = sol; % 空间温度场矩阵

fprintf('  [完成] PDE 求解完成，最终中心温度: %.2f K, 边界温度: %.2f K\n\n', ...
        T_solution(end, 1), T_solution(end, end));

%% 4. 学术论文级双联出图 (3D时空曲面 + 关键时刻截面曲线)
fprintf('[Step 2] 正在绘制学术级 PDE 时空演化图...\n');

fig = figure('Color', 'w', 'Position', [100, 100, 1100, 500], 'Visible', 'off');
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 子图 1: 3D 瞬态时空温度分布曲面
nexttile(1);
[X_grid, T_grid] = meshgrid(x_mesh, t_mesh / 3600.0); % 时间转化为小时
surf(X_grid, T_grid, T_solution, 'EdgeColor', 'none');
colormap(turbo);
cbar = colorbar;
cbar.Label.String = 'Temperature $T$ (K)';
cbar.Label.Interpreter = 'latex';
cbar.Label.FontSize = 11;
view(35, 30); grid on; box on;
xlabel('Position $x$ (m)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Time $t$ (hours)', 'Interpreter', 'latex', 'FontSize', 11);
zlabel('Temperature $T(x,t)$ (K)', 'Interpreter', 'latex', 'FontSize', 11);
title('Transient Temperature Field $T(x,t)$', 'Interpreter', 'latex', 'FontSize', 12);

% 子图 2: 关键时刻空间温度截面曲线族
nexttile(2);
time_slices = [1, 25, 50, 75, 100];
colors = parula(length(time_slices) + 1);

hold on;
for k = 1:length(time_slices)
    idx = time_slices(k);
    t_hrs = t_mesh(idx) / 3600.0;
    plot(x_mesh, T_solution(idx, :), 'LineWidth', 2.0, 'Color', colors(k, :), ...
         'DisplayName', sprintf('$t = %.1f\\;\\mathrm{h}$', t_hrs));
end
yline(p.T_ambient, 'k--', 'Ambient $T_{\infty}$', 'Interpreter', 'latex');
grid on; box on;
xlabel('Position $x$ (m)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Temperature $T$ (K)', 'Interpreter', 'latex', 'FontSize', 11);
title('Radial Temperature Profiles over Time', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northeast', 'Interpreter', 'latex');

exportgraphics(fig, 'pde_diffusion_result.png', 'Resolution', 300);
fprintf('  [完成] PDE 图表已无损导出至 pde_diffusion_result.png (300 DPI)\n\n');


%% ===================== pdepe 核心定义子函数 =====================

% 1. PDE 方程定义: c * du/dt = x^(-m) * d/dx(x^m * f) + s
function [c, f, s] = pde_equation(~, ~, ~, dudx, p)
    % 标准热传导: rho * cp * dT/dt = d/dx(k * dT/dx)
    c = p.rho * p.cp;
    f = p.k_thermal * dudx; % 通量项 (热流密度)
    s = 0.0;                % 内生热源项 (若有化学反应生热可在此添加)
end

% 2. 初始条件函数: u(x, 0)
function u0 = pde_initial(~, p)
    u0 = p.T_init; % 初始全域均匀温度
end

% 3. 边界条件函数: p + q * f = 0
function [pl, ql, pr, qr] = pde_boundary(~, ~, ~, ur, ~, p)
    % 左边界 (x = 0, 对称中心): dT/dx = 0 -> 0 + 1 * f = 0
    pl = 0;
    ql = 1;
    
    % 右边界 (x = L_total, 对流边界): -k * dT/dx = h * (T - T_ambient)
    % 转换形式: h * (ur - T_ambient) + 1 * f = 0
    pr = p.h_conv * (ur - p.T_ambient);
    qr = 1;
end
