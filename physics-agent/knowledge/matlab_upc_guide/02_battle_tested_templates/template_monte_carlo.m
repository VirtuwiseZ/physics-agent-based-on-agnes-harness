%% template_monte_carlo.m - 环境随机扰动与蒙特卡洛落点散布统计模版
% 适用题材：阵风扰动(2020B/2025B)、守门员防守概率(2022B)、喷泉水滴扩散(2014B)、行星碎片撞击(2021B)
% 核心技术：正态扰动抽样 + 批量矢量化蒙特卡洛计算 + 95%协方差置信椭圆 (CEP) + 命中概率直方图
% 编写环境：MATLAB R2023b 及以上

clear; clc; close all;

%% 1. 蒙特卡洛抽样规模与扰动参数定义
N_samples = 2000; % 蒙特卡洛模拟总次数 (通常 1000~5000 次)

% 名义工作基准点 (Nominal Operating Point)
v0_mean    = 380.0;   % 初速期望值 (m/s)
theta_mean = deg2rad(28.5); % 发射仰角期望值 (rad)
W_mean     = 5.0;     % 横风期望值 (m/s)
target_x   = 1200.0;  % 目标中心 X (m)
target_z   = 0.0;     % 目标中心 Z (m)
target_rad = 15.0;    % 目标有效破坏/命中半径 (m)

% 物理扰动方差设定 (反映制造公差与自然气象扰动)
sigma_v     = 3.5;              % 初速度标准差 (m/s, ~1%)
sigma_theta = deg2rad(0.35);    % 瞄准角标准差 (rad, ~0.35 deg)
sigma_w     = 2.0;              % 阵风扰动标准差 (m/s)

fprintf('====================================================\n');
fprintf('  UPC 蒙特卡洛随机不确定性模拟器 (Monte Carlo Dispersion)\n');
fprintf('  采样规模: N = %d 次\n', N_samples);
fprintf('  初速扰动: N(%.1f, %.1f^2) m/s\n', v0_mean, sigma_v);
fprintf('  角度扰动: N(%.2f°, %.2f°^2)\n', rad2deg(theta_mean), rad2deg(sigma_theta));
fprintf('  横风扰动: N(%.1f, %.1f^2) m/s\n', W_mean, sigma_w);
fprintf('====================================================\n\n');

%% 2. 生成随机抽样样本集
rng(42); % 固定随机种子，保证可复现性
v0_samples    = v0_mean + sigma_v * randn(N_samples, 1);
theta_samples = theta_mean + sigma_theta * randn(N_samples, 1);
w_samples     = W_mean + sigma_w * randn(N_samples, 1);

%% 3. 批量计算落点坐标分布 (X_impact, Z_impact)
fprintf('[Step 1] 正在进行 %d 次弹道落点批量解算...\n', N_samples);

g = 9.80665;
k = 0.0011; % 空气阻力系数

X_impact = zeros(N_samples, 1);
Z_impact = zeros(N_samples, 1);

tic;
for i = 1:N_samples
    v0 = v0_samples(i);
    th = theta_samples(i);
    w_z = w_samples(i);
    
    % 近似解析与积分结合的单次落点
    t_flight = 2 * v0 * sin(th) / g * (1 - 0.35 * k * v0); % 阻力衰减飞行时间
    x_land   = v0 * cos(th) * t_flight * (1 - 0.45 * k * v0);
    z_land   = 0.5 * (w_z * 0.8) * t_flight; % 侧风致偏
    
    X_impact(i) = x_land;
    Z_impact(i) = z_land;
end
calc_time = toc;
fprintf('  [完成] 批量计算完成，耗时: %.2f 秒\n', calc_time);

%% 4. 统计指标提取与命中概率计算
dev_x = X_impact - target_x;
dev_z = Z_impact - target_z;
distance_to_target = sqrt(dev_x.^2 + dev_z.^2);

% 计算圆概率误差 CEP (Circular Error Probable: 50% 弹丸落入的半径)
cep_50 = median(distance_to_target);

% 计算目标命中率
hits = sum(distance_to_target <= target_rad);
hit_probability = (hits / N_samples) * 100.0;

fprintf('\n=== 蒙特卡洛统计指标 ===\n');
fprintf('  落点中心期望:   (X = %.2f m, Z = %.2f m)\n', mean(X_impact), mean(Z_impact));
fprintf('  纵向标准差 sigma_x: %.2f m | 横向标准差 sigma_z: %.2f m\n', std(X_impact), std(Z_impact));
fprintf('  50%% 圆概率误差 (CEP): %.2f m\n', cep_50);
fprintf('  目标命中概率 (半径 %.1fm 内): %.2f%%\n', target_rad, hit_probability);

%% 5. 95% 协方差散布置信椭圆 (Covariance Error Ellipse) 计算
cov_matrix = cov(X_impact, Z_impact);
[eig_vec, eig_val] = eig(cov_matrix);

% 95% 置信度对应的卡方乘数 (自由度=2时，chi2inv(0.95, 2) ~ 5.991)
chisquare_val = 2.4477; % sqrt(5.991)
a_semi = chisquare_val * sqrt(eig_val(1,1)); % 半长轴
b_semi = chisquare_val * sqrt(eig_val(2,2)); % 半短轴
phi_rot = atan2(eig_vec(2,1), eig_vec(1,1)); % 旋转角

% 参数方程构建置信椭圆
theta_ellipse = linspace(0, 2*pi, 100);
ellipse_x = mean(X_impact) + a_semi * cos(theta_ellipse) * cos(phi_rot) - b_semi * sin(theta_ellipse) * sin(phi_rot);
ellipse_z = mean(Z_impact) + a_semi * cos(theta_ellipse) * sin(phi_rot) + b_semi * sin(theta_ellipse) * cos(phi_rot);

%% 6. 学术出版级出图 (散点分布 + 置信椭圆 + 边际直方图)
fprintf('\n[Step 2] 正在绘制学术级散布相图...\n');

fig = figure('Color', 'w', 'Position', [100, 100, 1100, 500]);
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 子图 1: 二维地表落点散布与 95% 置信椭圆
nexttile(1);
scatter(X_impact, Z_impact, 10, [0.3 0.5 0.9], 'filled', 'MarkerFaceAlpha', 0.4, 'DisplayName', '落点样本');
hold on;
plot(ellipse_x, ellipse_z, 'r-', 'LineWidth', 2.2, 'DisplayName', '95% 散布置信椭圆');

% 绘制目标区域
th_target = linspace(0, 2*pi, 60);
plot(target_x + target_rad*cos(th_target), target_z + target_rad*sin(th_target), 'k-', 'LineWidth', 2.0, 'DisplayName', '目标有效区域');
plot(target_x, target_z, 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 12, 'DisplayName', '目标靶心');

grid on; box on; axis equal;
xlabel('射程 X 方向落点 (m)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('侧向 Z 方向落点 (m)', 'Interpreter', 'latex', 'FontSize', 11);
title('落点蒙特卡洛散布与 95% 置信椭圆', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northeast', 'Interpreter', 'latex');

% 子图 2: 目标偏离距离直方图与概率密度
nexttile(2);
histogram(distance_to_target, 35, 'Normalization', 'pdf', 'FaceColor', [0.2 0.7 0.5], 'EdgeColor', 'w');
hold on;
xline(cep_50, 'r--', sprintf('CEP (50%%) = %.1fm', cep_50), 'LineWidth', 2.0, 'Interpreter', 'latex');
xline(target_rad, 'k-', sprintf('目标半径 = %.1fm', target_rad), 'LineWidth', 2.0, 'Interpreter', 'latex');

grid on; box on;
xlabel('相对目标偏离距离 (m)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('概率密度 (PDF)', 'Interpreter', 'latex', 'FontSize', 11);
title('目标偏离距离分布与 CEP 统计', 'Interpreter', 'latex', 'FontSize', 12);

exportgraphics(fig, 'monte_carlo_result.png', 'Resolution', 300);
fprintf('  [完成] 散布图已无损导出至 monte_carlo_result.png (300 DPI)\n\n');
