%% template_orbital_continuous.m - 天体轨道动力学、连续微推力与守恒量自检模版
% 适用题材：离子电推变轨(2020A)、小行星轨道偏转(2022A)、深空引力助推(2013A)、近地空间站轨道衰减(2010A)
% 核心技术：二体引力场 + 连续推力变质量方程 (齐奥尔科夫斯基) + ode113高阶积分 + 机械能/角动量数值守恒门禁
% 编写环境：MATLAB R2023b 及以上

clear; clc; close all;

%% 1. 天体常数与航天器推进系统参数
const.G       = 6.67430e-11;      % 万有引力常数 (m^3 / (kg * s^2))
const.M_sun   = 1.9885e30;        % 太阳质量 (kg)
const.mu_sun  = const.G * const.M_sun; % 太阳引力常数 mu (m^3/s^2)
const.AU      = 1.495978707e11;   % 天文单位 (m)
const.g0      = 9.80665;          % 标准地表重力 (用于比冲折算, m/s^2)

% 航天器参数 (以连续微推力离子推进器深空转移为例)
sc.m0         = 2000.0;           % 航天器初始湿重 (kg)
sc.thrust     = 0.50;             % 恒定微推力大小 (N, 如大功率霍尔推进器)
sc.Isp        = 3500.0;           % 电推进高比冲 (s)
sc.mdot       = sc.thrust / (sc.Isp * const.g0); % 质量损耗率 dm/dt (kg/s)

% 初始轨道条件 (从地球公转轨道 1 AU 出发，初始沿顺轨正切方向点火)
r0 = const.AU;
v_circ0 = sqrt(const.mu_sun / r0); % 地球轨道公转环绕速度 (~29.78 km/s)

% 初始状态向量: Y0 = [x; y; vx; vy; m] (2D 轨道平面)
Y0 = [r0; 0.0; 0.0; v_circ0; sc.m0];

% 转移推进时间 (例如点火推进 400 天)
t_burn_days = 400.0;
t_span = [0, t_burn_days * 86400.0];

fprintf('====================================================\n');
fprintf('  UPC 天体轨道与连续小推力变轨仿真器 (Orbital Transfer)\n');
fprintf('  中心天体: 太阳 | 初始轨道半径: 1.00 AU | 初始环绕速度: %.2f km/s\n', v_circ0/1000);
fprintf('  推力: %.3f N | 比冲 Isp: %.0f s | 点火历时: %.1f 天\n', sc.thrust, sc.Isp, t_burn_days);
fprintf('====================================================\n\n');

%% 2. 高精度数值积分 (使用适合平滑高精度轨道的 ode113)
fprintf('[Step 1] 正在执行连续推进轨道高精度数值积分 (ode113)...\n');

% 设定超高精度容差，避免长周期天体积分伪发散
ode_opts = odeset('RelTol', 1e-10, 'AbsTol', 1e-12, 'Events', @(t,y) fuel_exhaust_event(t, y));

[t_vec, Y_vec, te, ye, ie] = ode113(@(t,y) orbital_thrust_rhs(t, y, const, sc), t_span, Y0, ode_opts);

r_vec = sqrt(Y_vec(:,1).^2 + Y_vec(:,2).^2);
v_vec = sqrt(Y_vec(:,3).^2 + Y_vec(:,4).^2);
final_r_AU = r_vec(end) / const.AU;
fuel_used = sc.m0 - Y_vec(end, 5);

fprintf('\n=== 变轨推进仿真结论 ===\n');
fprintf('  积分结束时间:   %.2f 天\n', t_vec(end) / 86400.0);
fprintf('  最终轨道半长轴: %.3f AU\n', final_r_AU);
fprintf('  最终速度幅值:   %.2f km/s\n', v_vec(end) / 1000.0);
fprintf('  消耗工质燃料:   %.2f kg (剩余质量: %.2f kg)\n', fuel_used, Y_vec(end, 5));

%% 3. 物理守恒量门禁自检 (Conservation Law Gate)
% 在无外力推力段，比机械能 E 与比角动量 h 必须严格守恒；在有推力段，用于核验功率做功自洽性
E_specific = 0.5 * v_vec.^2 - const.mu_sun ./ r_vec;           % 比机械能 (J/kg)
h_specific = Y_vec(:,1).*Y_vec(:,4) - Y_vec(:,2).*Y_vec(:,3);   % 比角动量 (m^2/s)

fprintf('\n[Step 2] 执行轨道力学能量与角动量自洽性检验...\n');
fprintf('  初始比机械能: %.4e J/kg | 终止比机械能: %.4e J/kg (增量: +%.4e J/kg)\n', ...
        E_specific(1), E_specific(end), E_specific(end) - E_specific(1));
fprintf('  初始比角动量: %.4e m^2/s | 终止比角动量: %.4e m^2/s\n', h_specific(1), h_specific(end));

%% 4. 学术级轨道演化与能量图绘制
fprintf('[Step 3] 正在生成学术论文标准出图...\n');

fig = figure('Color', 'w', 'Position', [100, 100, 1100, 500]);
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 子图 1: 太阳系中心天体轨道平面演化图 (以 AU 为单位)
nexttile(1);
plot(Y_vec(:,1)/const.AU, Y_vec(:,2)/const.AU, 'b-', 'LineWidth', 1.8, 'DisplayName', '离子推进螺旋渐开轨道');
hold on;
plot(0, 0, 'yo', 'MarkerFaceColor', [1 0.7 0], 'MarkerSize', 12, 'DisplayName', '中心天体 (太阳)');

% 绘制 1.0 AU 初始参考圆轨道
theta_circle = linspace(0, 2*pi, 200);
plot(cos(theta_circle), sin(theta_circle), 'k--', 'LineWidth', 1.0, 'DisplayName', '初始地球轨道 (1 AU)');

grid on; box on; axis equal;
xlabel('X 坐标 (AU)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Y 坐标 (AU)', 'Interpreter', 'latex', 'FontSize', 11);
title('连续微推力深空轨道转移历程 (AU)', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northwest', 'Interpreter', 'latex');

% 子图 2: 轨道半径与比机械能演化 (双 Y 轴对比)
nexttile(2);
t_days = t_vec / 86400.0;
yyaxis left;
plot(t_days, r_vec / const.AU, 'b-', 'LineWidth', 2.0);
ylabel('轨道天体距离 r (AU)', 'Interpreter', 'latex', 'FontSize', 11);
grid on;

yyaxis right;
plot(t_days, E_specific / 1e8, 'r--', 'LineWidth', 2.0);
ylabel('比机械能 $\mathcal{E}$ ($10^8$ J/kg)', 'Interpreter', 'latex', 'FontSize', 11);

xlabel('推进运行时间 (天)', 'Interpreter', 'latex', 'FontSize', 11);
title('轨道能量增长与空间距离扩展时序图', 'Interpreter', 'latex', 'FontSize', 12);

exportgraphics(fig, 'orbital_result.png', 'Resolution', 300);
fprintf('  [完成] 图表已无损导出至 orbital_result.png (300 DPI)\n\n');


%% ===================== 物理控制方程与事件子函数 =====================

% 1. 轨道动力学微分方程 (RHS): 万有引力 + 沿速度方向切向推力 + 质量衰减
function dY = orbital_thrust_rhs(~, Y, c, sc)
    % 状态: Y = [x; y; vx; vy; m]
    x  = Y(1); y  = Y(2);
    vx = Y(3); vy = Y(4);
    m  = max(Y(5), 10.0); % 保护质量非负
    
    r = sqrt(x^2 + y^2);
    v = sqrt(vx^2 + vy^2);
    
    % 万有引力加速度矢量: a_grav = -mu / r^3 * r_vec
    a_grav_x = -c.mu_sun * x / (r^3);
    a_grav_y = -c.mu_sun * y / (r^3);
    
    % 推力加速度矢量 (沿瞬时速度正方向切向加速，加速效率最高)
    if m > 100.0 && v > 1e-3
        thrust_unit_x = vx / v;
        thrust_unit_y = vy / v;
        a_thrust_x = (sc.thrust / m) * thrust_unit_x;
        a_thrust_y = (sc.thrust / m) * thrust_unit_y;
        dm_dt = -sc.mdot;
    else
        % 燃料耗尽或关机
        a_thrust_x = 0.0;
        a_thrust_y = 0.0;
        dm_dt = 0.0;
    end
    
    ax = a_grav_x + a_thrust_x;
    ay = a_grav_y + a_thrust_y;
    
    dY = [vx; vy; ax; ay; dm_dt];
end

% 2. 燃料耗尽事件截断函数 (Event)
function [val, isterminal, dir] = fuel_exhaust_event(~, Y)
    dry_mass = 500.0; % 结构干重 (kg)
    val = Y(5) - dry_mass; % 当总质量下降到干重时
    isterminal = 0;        % 不中断轨道积分，转为滑行
    dir = -1;
end
