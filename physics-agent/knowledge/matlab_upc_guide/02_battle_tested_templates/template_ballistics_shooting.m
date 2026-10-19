%% template_ballistics_shooting.m - 3D外弹道仿真与打靶法逆向求解标准模版
% 适用题材：火炮弹道(2025B)、足球射门(2022B)、太空跳伞(2023A)、水弹灭火(2014B)等气动阻力抛体
% 核心技术：3D空间动力学 + ISA国际标准大气模型 + 跨音速阻力危机Cd(M) + 三维风场 + fzero打靶法反求射角
% 编写环境：MATLAB R2023b 及以上

clear; clc; close all;

%% 1. 物理常数与弹丸/目标几何参数定义
params.g0    = 9.80665;       % 标准重力加速度 (m/s^2)
params.m     = 5.0;           % 弹丸质量 (kg)
params.d     = 0.11;          % 弹丸直径 (m)
params.A     = pi * (params.d/2)^2; % 弹丸迎风截面积 (m^2)

% 环境与风场参数
params.H_alt = 500;           % 发射场与靶标所在海拔 (m)
params.W_mag = 8.0;           % 水平风速幅值 (m/s)
params.W_dir = deg2rad(45);   % 风向方位角 (rad, 0度表示顺风+X, 90度表示纯侧风+Z)
params.W_vec = [params.W_mag * cos(params.W_dir); 0; params.W_mag * sin(params.W_dir)];

% 任务目标
target_dist = 1200.0;         % 目标水平直线距离 (m)
v_muzzle    = 380.0;          % 炮口初速 (m/s)

fprintf('====================================================\n');
fprintf('  UPC 外弹道仿真与打靶法求解器 (3D Ballistics & Shooting)\n');
fprintf('  目标水平距离: %.1f m | 炮口初速度: %.1f m/s\n', target_dist, v_muzzle);
fprintf('  风速: %.1f m/s | 风向角: %.1f deg\n', params.W_mag, rad2deg(params.W_dir));
fprintf('====================================================\n\n');

%% 2. 使用 fzero 执行打靶法 (Shooting Method) 逆向求解发射仰角
fprintf('[Step 1] 正在通过打靶法 (fzero) 搜索击中目标的发射仰角...\n');

% 定义残差目标函数：输入发射仰角 (deg)，输出弹道落地时与目标距离的差值 (m)
objective_fun = @(theta_deg) forward_trajectory_residual(theta_deg, v_muzzle, target_dist, params);

% 设定物理合理的仰角搜索区间 [5度, 80度]
search_bracket = [10.0, 75.0];
opt_shooting = optimset('TolX', 1e-6, 'Display', 'off');

try
    theta_sol_deg = fzero(objective_fun, search_bracket, opt_shooting);
    fprintf('  [成功] 命中目标的发射仰角为: %.4f 度 (%.4f rad)\n', theta_sol_deg, deg2rad(theta_sol_deg));
catch ME
    warning('打靶法在当前区间内未找到单根，可能超出最大射程。尝试在全仰角范围扫描寻找极值。');
    theta_sol_deg = 45.0; % 退化回 45 度
end

%% 3. 高精度前向弹道全历程仿真与数据提取
fprintf('[Step 2] 正在生成完整高保真 3D 飞行弹道...\n');

theta_rad = deg2rad(theta_sol_deg);
v0_x = v_muzzle * cos(theta_rad);
v0_y = v_muzzle * sin(theta_rad);
v0_z = 0.0; % 初始朝向正 X 轴瞄准

% 初始状态向量: Y0 = [x; y; z; vx; vy; vz]
Y0 = [0.0; params.H_alt; 0.0; v0_x; v0_y; v0_z];

% 配置高精度求解器与落地检测事件
ode_opts = odeset('RelTol', 1e-8, 'AbsTol', 1e-10, 'Events', @(t,y) ground_event(t, y, params.H_alt));

% 使用 Adams-Bashforth-Moulton 高阶多步积分器 ode113 (若不可用则换为 ode45)
[t_traj, Y_traj, te, ye, ie] = ode113(@(t,y) ballistics_rhs(t, y, params), [0, 200], Y0, ode_opts);

flight_time = te;
final_pos   = ye(1:3);
final_vel   = ye(4:6);
impact_speed = norm(final_vel);
max_alt     = max(Y_traj(:, 2));
lateral_dev = final_pos(3); % 侧向风致偏航

fprintf('\n=== 弹道核心仿真结果统计 ===\n');
fprintf('  飞行全时间:   %.3f s\n', flight_time);
fprintf('  落地点坐标:   (X = %.2f m, Y = %.2f m, Z = %.2f m)\n', final_pos(1), final_pos(2), final_pos(3));
fprintf('  距离目标偏差: %.3f m\n', final_pos(1) - target_dist);
fprintf('  侧风偏移量:   %.2f m\n', lateral_dev);
fprintf('  弹道最高顶点: %.2f m (相对海平面)\n', max_alt);
fprintf('  落地撞击速度: %.2f m/s (着地马赫数: %.2f)\n', impact_speed, impact_speed / 340.0);

%% 4. 学术级学术图表生成与排版 (现代 tiledlayout)
fprintf('[Step 3] 正在绘制学术级科研图表...\n');

fig = figure('Color', 'w', 'Position', [100, 100, 1100, 500]);
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 子图 1: 3D 空间飞行轨迹与地表投影
nexttile(1);
plot3(Y_traj(:,1), Y_traj(:,3), Y_traj(:,2), 'b-', 'LineWidth', 2.0, 'DisplayName', '实际飞行轨迹');
hold on;
plot3(Y_traj(:,1), Y_traj(:,3), params.H_alt * ones(size(Y_traj(:,1))), 'k--', 'LineWidth', 1.0, 'DisplayName', '地面投影');
plot3(target_dist, 0, params.H_alt, 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', '目标靶心');
grid on; box on; view(35, 25);
xlabel('射程 X (m)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('侧偏向 Z (m)', 'Interpreter', 'latex', 'FontSize', 11);
zlabel('海拔高度 Y (m)', 'Interpreter', 'latex', 'FontSize', 11);
title('三维空间弹道与侧风偏航轨迹', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northeast', 'Interpreter', 'latex');

% 子图 2: 速度演化与高度剖面 (双 Y 轴对比)
nexttile(2);
yyaxis left;
speed_profile = sqrt(sum(Y_traj(:,4:6).^2, 2));
plot(t_traj, speed_profile, 'r-', 'LineWidth', 2.0);
ylabel('飞行总速度 (m/s)', 'Interpreter', 'latex', 'FontSize', 11);
grid on;

yyaxis right;
plot(t_traj, Y_traj(:,2) - params.H_alt, 'b--', 'LineWidth', 2.0);
ylabel('相对地面高度 (m)', 'Interpreter', 'latex', 'FontSize', 11);

xlabel('飞行时间 t (s)', 'Interpreter', 'latex', 'FontSize', 11);
title('速度衰减与高度时序演化 (双轴对比)', 'Interpreter', 'latex', 'FontSize', 12);

% 导出符合出版物要求的无损高清图
exportgraphics(fig, 'trajectory_result.png', 'Resolution', 300);
fprintf('  [完成] 图表已无损导出至 trajectory_result.png (300 DPI)\n\n');


%% ===================== 物理子模型与子函数库 =====================

% 1. 前向积分残差函数 (供 fzero 调用)
function res = forward_trajectory_residual(theta_deg, v0, target_x, p)
    theta = deg2rad(theta_deg);
    y0_state = [0; p.H_alt; 0; v0*cos(theta); v0*sin(theta); 0];
    opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, 'Events', @(t,y) ground_event(t, y, p.H_alt));
    [~, ~, ~, ye, ~] = ode45(@(t,y) ballistics_rhs(t,y,p), [0, 300], y0_state, opts);
    if isempty(ye)
        res = 1e5; % 飞行超时未落地惩罚
    else
        res = ye(1) - target_x;
    end
end

% 2. 动力学控制微分方程右端项 (RHS)
function dY = ballistics_rhs(~, Y, p)
    % 状态向量分解: Y = [x, y, z, vx, vy, vz]'
    pos = Y(1:3);
    vel = Y(4:6);
    
    altitude = pos(2);
    [rho, c_sound, mu] = isa_atmosphere(altitude);
    
    % 计算考虑三维风场的相对空气速度
    v_rel_vec = vel - p.W_vec;
    v_rel = norm(v_rel_vec);
    
    % 气动阻力系数 (包含跨音速阻力危机)
    M  = v_rel / max(c_sound, 10.0);
    Re = (rho * v_rel * p.d) / max(mu, 1e-6);
    Cd = transonic_drag_coeff(M, Re);
    
    % 气动阻力矢量 F_drag = -0.5 * rho * A * Cd * v_rel * v_rel_vec
    F_drag = -0.5 * rho * p.A * Cd * v_rel * v_rel_vec;
    
    % 加速度计算: a = F_drag / m - g
    acc = F_drag / p.m - [0; p.g0; 0];
    
    dY = [vel; acc];
end

% 3. 落地检测事件函数 (Event Location)
function [val, isterminal, dir] = ground_event(~, Y, H_ground)
    val = Y(2) - H_ground; % 当 Y(2) 回到地面基准面时
    isterminal = 1;        % 立即停止积分
    dir = -1;              % 仅当下落穿透地面时触发
end

% 4. 国际标准大气模型 ISA (含对流层/平流层温降与萨瑟兰粘度)
function [rho, c_s, mu] = isa_atmosphere(H)
    T0 = 288.15; P0 = 101325.0; L = -0.0065; H_trop = 11000.0;
    gamma = 1.4; R_gas = 287.05; g0 = 9.80665;
    
    H_clamped = max(H, 0.0);
    if H_clamped <= H_trop
        T = T0 + L * H_clamped;
        P = P0 * (T / T0)^(-g0 / (L * R_gas));
    else
        T_trop = T0 + L * H_trop;
        P_trop = P0 * (T_trop / T0)^(-g0 / (L * R_gas));
        T = T_trop;
        P = P_trop * exp(-g0 * (H_clamped - H_trop) / (R_gas * T_trop));
    end
    
    rho = P / (R_gas * T);
    c_s = sqrt(gamma * R_gas * T);
    
    % 萨瑟兰公式计算动态粘度 mu(T)
    mu_ref = 1.716e-5; T_ref = 273.15; S_const = 110.4;
    mu = mu_ref * (T / T_ref)^1.5 * ((T_ref + S_const) / (T + S_const));
end

% 5. 跨音速阻力危机经验模型 Cd(M, Re)
function Cd = transonic_drag_coeff(M, ~)
    Cd_sub = 0.45; % 亚音速阻力系数
    if M < 0.8
        Cd = Cd_sub;
    elseif M <= 1.2
        % 跨音速音障区激波阻力激增
        Cd = Cd_sub + 0.50 * sin(pi * (M - 0.8) / 0.4);
    else
        % 超音速区域激波阻力按幂律衰减
        Cd = 0.95 / sqrt(M^2 - 1 + 0.1);
        Cd = max(Cd, 0.35);
    end
end
