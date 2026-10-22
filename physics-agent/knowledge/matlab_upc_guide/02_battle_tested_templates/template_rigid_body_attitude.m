%% template_rigid_body_attitude.m - 3D 刚体姿态动力学与欧拉动力学方程数值仿真模板
% 适用题材：卫星/航天器姿态翻滚、下落物体自旋稳定、非对称刚体自由翻转(贾尼别科夫效应/中主轴失稳)
% 核心技术：欧拉动力学方程 (Euler equations of motion) + 四元数/欧拉角运动学 + 动能/角动量不变量校验
% 编写环境：MATLAB R2023b 及以上

clear; clc; close all;

%% 1. 物理参数与主转动惯量定义
% 设定三轴主转动惯量 (kg*m^2)
% 选取 I1 < I2 < I3，用于观察经典中主轴失稳旋转或外力矩下进动
I1 = 1.0;   % 最小主惯量
I2 = 2.0;   % 中间主惯量
I3 = 3.0;   % 最大主惯量
I_tensor = diag([I1, I2, I3]);
inv_I = diag([1/I1, 1/I2, 1/I3]);

% 初始角速度 (rad/s)
% 沿中主轴 (y轴) 为主，并施加微小的 x 轴扰动
w0 = [0.1; 5.0; 0.1]; 

% 初始姿态角 (欧拉角: 滚转 phi, 俯仰 theta, 偏航 psi, 单位 rad)
euler0 = [0.0; 0.0; 0.0];

% 合并初始状态向量 Y0 = [omega_x; omega_y; omega_z; phi; theta; psi]
Y0 = [w0; euler0];

t_span = [0, 30]; % 积分时长 30 秒

%% 2. 数值积分求解 (使用高精度自适应步长 ode45/ode113)
fprintf('[Step 1] 正在进行三维刚体欧拉动力学与运动学耦合数值积分...\n');

opts = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);
[t, Y] = ode45(@(t, y) rigid_body_ode(t, y, I1, I2, I3), t_span, Y0, opts);

w_x = Y(:, 1);
w_y = Y(:, 2);
w_z = Y(:, 3);
phi = Y(:, 4);
theta = Y(:, 5);
psi = Y(:, 6);

%% 3. 守恒量与物理自洽性校验 (动能与总角动量)
% 无外力矩下，刚体定点转动总动能 T 与角动量模长 L 必须严格守恒
T_kinetic = 0.5 * (I1 * w_x.^2 + I2 * w_y.^2 + I3 * w_z.^2);
L_mag = sqrt((I1 * w_x).^2 + (I2 * w_y).^2 + (I3 * w_z).^2);

delta_T_rel = abs(T_kinetic - T_kinetic(1)) / T_kinetic(1);
delta_L_rel = abs(L_mag - L_mag(1)) / L_mag(1);

fprintf('=== 守恒量校验指标 ===\n');
fprintf('  初始转动动能: %.6f J | 最大相对漂移: %.2e\n', T_kinetic(1), max(delta_T_rel));
fprintf('  初始总角动量: %.6f N*m*s | 最大相对漂移: %.2e\n', L_mag(1), max(delta_L_rel));

%% 4. 学术出版级出图 (时序角速度演化 + 相空间动能椭球轨迹)
fprintf('[Step 2] 正在绘制学术级姿态响应与角动量相图...\n');

fig = figure('Color', 'w', 'Position', [100, 100, 1100, 480], 'Visible', 'off');
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 子图 1: 三轴角速度时域演化
nexttile(1);
plot(t, w_x, 'b-', 'LineWidth', 1.8, 'DisplayName', '$\omega_x$ (Minor axis)');
hold on;
plot(t, w_y, 'r--', 'LineWidth', 1.8, 'DisplayName', '$\omega_y$ (Intermediate axis)');
plot(t, w_z, 'g:', 'LineWidth', 1.8, 'DisplayName', '$\omega_z$ (Major axis)');
grid on; box on;
xlabel('Time $t$ (s)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Angular Velocity (rad/s)', 'Interpreter', 'latex', 'FontSize', 11);
title('Angular Velocity Time History (Intermediate Axis Instability)', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northeast', 'Interpreter', 'latex');

% 子图 2: 角速度相空间轨迹 (Poinsot Ellipsoid Phase Space)
nexttile(2);
plot3(w_x, w_y, w_z, 'k-', 'LineWidth', 1.5);
hold on;
plot3(w0(1), w0(2), w0(3), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Initial State');
grid on; box on; view(35, 25);
xlabel('$\omega_x$ (rad/s)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('$\omega_y$ (rad/s)', 'Interpreter', 'latex', 'FontSize', 11);
zlabel('$\omega_z$ (rad/s)', 'Interpreter', 'latex', 'FontSize', 11);
title('Angular Velocity Phase Trajectory ($\omega_x - \omega_y - \omega_z$)', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northeast', 'Interpreter', 'latex');

exportgraphics(fig, 'rigid_body_attitude_result.png', 'Resolution', 300);
fprintf('  [完成] 图表已无损导出至 rigid_body_attitude_result.png (300 DPI)\n\n');

%% 5. 状态微分方程局部函数
function dydt = rigid_body_ode(t, y, I1, I2, I3)
    % 状态分解
    wx = y(1);
    wy = y(2);
    wz = y(3);
    phi = y(4);
    theta = y(5);
    psi = y(6);

    % 欧拉动力学方程 (主轴坐标系，无外力矩情形 M_ext = 0)
    dwx_dt = ((I2 - I3) / I1) * wy * wz;
    dwy_dt = ((I3 - I1) / I2) * wz * wx;
    dwz_dt = ((I1 - I2) / I3) * wx * wy;

    % 欧拉角运动学方程 (Z-Y-X 顺序转换, 奇异点避开 theta = +/- pi/2)
    cos_theta = cos(theta);
    if abs(cos_theta) < 1e-4
        cos_theta = 1e-4 * sign(cos_theta);
    end
    
    dphi_dt   = wx + (wy * sin(phi) + wz * cos(phi)) * tan(theta);
    dtheta_dt = wy * cos(phi) - wz * sin(phi);
    dpsi_dt   = (wy * sin(phi) + wz * cos(phi)) / cos_theta;

    dydt = [dwx_dt; dwy_dt; dwz_dt; dphi_dt; dtheta_dt; dpsi_dt];
end
