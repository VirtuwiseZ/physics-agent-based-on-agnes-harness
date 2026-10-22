%% template_lorentz_particle_drift.m - 带电粒子在复合电磁场中的运动与绝热不变量仿真模板
% 适用题材：磁约束托卡马克、范艾伦辐射带粒子捕获、正交 E x B 场粒子漂移、极光机理
% 核心技术：牛顿-洛伦兹动力学方程 (Lorentz force) + 磁矩绝热不变量 (mu) 校验 + 3D 轨迹与磁力线可视化
% 编写环境：MATLAB R2023b 及以上

clear; clc; close all;

%% 1. 物理参数与场强环境定义
q = 1.602176634e-19;  % 粒子电荷量 (C, 质子)
m = 1.67262192369e-27; % 粒子质量 (kg, 质子)

% 复合场配置：磁镜场 (Magnetic Mirror / Bottle) 搭配横向匀强微弱电场
% B(x,y,z) 配置：轴对称梯度磁场，在两端收缩汇聚
% E(x,y,z) 配置：恒定静电场，驱动 E x B 漂移
B0 = 1.0;     % 轴心基准磁场强度 (T)
L_mirror = 1.0; % 磁镜特征半长 (m)
E_vec = [0; 50.0; 0]; % 横向电场 (V/m, 沿 y 轴)

% 初始位置与速度 (m, m/s)
r0 = [0.05; 0.0; 0.0]; % 偏离轴心 5 cm
v_perp = 2.0e5;        % 初始垂直速度 (m/s)
v_parallel = 1.5e5;    % 初始平行轴线速度 (m/s)
v0 = [0.0; v_perp; v_parallel];

Y0 = [r0; v0];
t_span = [0, 8.0e-5]; % 积分时长 80 微秒 (经历数百次回旋与数次反弹)

%% 2. 状态微分方程高精度数值积分 (ode113 或 ode45)
fprintf('[Step 1] 正在进行洛伦兹力动力学方程高精度数值积分 (RelTol=1e-8)...\n');

opts = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);
[t, Y] = ode45(@(t, y) lorentz_ode(t, y, q, m, B0, L_mirror, E_vec), t_span, Y0, opts);

rx = Y(:, 1); ry = Y(:, 2); rz = Y(:, 3);
vx = Y(:, 4); vy = Y(:, 5); vz = Y(:, 6);

%% 3. 绝热不变量与回旋动力学指标分析
% 计算各时刻局部磁场 B 矢量与模长
N_pts = length(t);
B_mag = zeros(N_pts, 1);
v_perp_mag = zeros(N_pts, 1);
mu_magnetic = zeros(N_pts, 1);

for i = 1:N_pts
    B_local = get_magnetic_field(rx(i), ry(i), rz(i), B0, L_mirror);
    B_mag(i) = norm(B_local);
    b_hat = B_local / B_mag(i);
    
    v_vec = [vx(i); vy(i); vz(i)];
    v_par = dot(v_vec, b_hat);
    v_perp_vec = v_vec - v_par * b_hat;
    v_perp_mag(i) = norm(v_perp_vec);
    
    % 第一绝热不变量: 磁矩 mu = m * v_perp^2 / (2 * B)
    mu_magnetic(i) = 0.5 * m * (v_perp_mag(i)^2) / B_mag(i);
end

% 计算磁矩相对波动 (在绝热引导中心近似下，mu 守恒)
mu_mean = mean(mu_magnetic);
mu_std_rel = std(mu_magnetic) / mu_mean;

fprintf('=== 粒子物理动力学指标 ===\n');
fprintf('  平均磁矩 (第1绝热不变量): %.3e J/T\n', mu_mean);
fprintf('  磁矩相对波动标准差:       %.2f %%\n', mu_std_rel * 100);
fprintf('  回旋半径 (Larmor radius):   %.2f mm\n', (m * v_perp / (q * B0)) * 1000);

%% 4. 学术出版级出图 (3D 螺旋捕获轨迹 + 磁矩绝热守恒)
fprintf('[Step 2] 正在绘制学术级三维粒子漂移与磁矩守恒图...\n');

fig = figure('Color', 'w', 'Position', [100, 100, 1100, 480], 'Visible', 'off');
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 子图 1: 3D 螺旋回旋与磁镜捕获轨迹
nexttile(1);
plot3(rx * 1000, ry * 1000, rz * 1000, 'b-', 'LineWidth', 1.2, 'DisplayName', 'Proton Trajectory');
hold on;
plot3(rx(1)*1000, ry(1)*1000, rz(1)*1000, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 6, 'DisplayName', 'Start Point');
plot3(rx(end)*1000, ry(end)*1000, rz(end)*1000, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'DisplayName', 'End Point');
grid on; box on; view(45, 25);
xlabel('$X$ (mm)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('$Y$ (mm)', 'Interpreter', 'latex', 'FontSize', 11);
zlabel('$Z$ (mm)', 'Interpreter', 'latex', 'FontSize', 11);
title('3D Guiding-Center Drift and Magnetic Mirror Trapping', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northeast', 'Interpreter', 'latex');

% 子图 2: 第一绝热不变量 (磁矩 mu) 时序自洽性
nexttile(2);
plot(t * 1e6, mu_magnetic * 1e16, 'r-', 'LineWidth', 1.5, 'DisplayName', '$\mu(t) = m v_{\perp}^2 / (2B)$');
hold on;
yline(mu_mean * 1e16, 'k--', sprintf('Mean: %.2f', mu_mean*1e16), 'Interpreter', 'latex');
grid on; box on;
xlabel('Time $t$ ($\mu$s)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Magnetic Moment $\mu$ ($10^{-16}$ J/T)', 'Interpreter', 'latex', 'FontSize', 11);
title('First Adiabatic Invariant Invariance ($\mu \approx \mathrm{const}$)', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'southeast', 'Interpreter', 'latex');

exportgraphics(fig, 'lorentz_particle_drift_result.png', 'Resolution', 300);
fprintf('  [完成] 图表已无损导出至 lorentz_particle_drift_result.png (300 DPI)\n\n');

%% 5. 局部动力学与场强函数
function dydt = lorentz_ode(t, y, q, m, B0, L, E_vec)
    r = y(1:3);
    v = y(4:6);

    B = get_magnetic_field(r(1), r(2), r(3), B0, L);
    E = E_vec;

    % 洛伦兹力 F = q * (E + v x B)
    F = q * (E + cross(v, B));
    a = F / m;

    dydt = [v; a];
end

function B = get_magnetic_field(x, y, z, B0, L)
    % 轴对称线性近似磁镜场: B_z(z) = B0 * (1 + (z/L)^2)
    % 由麦克斯韦方程 div(B) = 0, 径向分量 B_r \approx -0.5 * r * dB_z/dz
    dBz_dz = 2 * B0 * z / (L^2);
    Bx = -0.5 * x * dBz_dz;
    By = -0.5 * y * dBz_dz;
    Bz = B0 * (1 + (z/L)^2);
    B = [Bx; By; Bz];
end
