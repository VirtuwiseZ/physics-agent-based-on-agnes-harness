%% template_wave_optics_diffraction.m - 波动光学干涉与衍射强度空间分布仿真模板
% 适用题材：单缝/多缝夫琅禾费衍射、圆孔衍射艾里斑(Rayleigh判据)、光学薄膜干涉、衍射光栅光谱
% 核心技术：标量波动光学衍射积分 + 贝塞尔函数 (besselj) + 2D 衍射光斑云图与 1D 强度剖面图
% 编写环境：MATLAB R2023b 及以上

clear; clc; close all;

%% 1. 光学系统物理参数定义
lambda = 632.8e-9;      % 光源波长 (He-Ne 激光, 632.8 nm)
k = 2 * pi / lambda;    % 光波数 (rad/m)

% 衍射孔径几何参数
R_aperture = 0.25e-3;   % 圆孔半径 a = 0.25 mm (直径 0.5 mm)
L_screen = 1.2;         % 孔径至观察屏距离 L = 1.2 m

% 观察屏网格空间范围 (-10 mm 到 +10 mm)
screen_size = 8.0e-3;   % 观察屏半宽 8 mm
N_grid = 400;           % 空间网格分辨率 400x400
x_vec = linspace(-screen_size, screen_size, N_grid);
y_vec = linspace(-screen_size, screen_size, N_grid);
[X, Y] = meshgrid(x_vec, y_vec);

%% 2. 空间光强场计算 (基于一阶第一类贝塞尔函数 besselj)
fprintf('[Step 1] 正在计算圆孔夫琅禾费衍射空间光强场 (Airy Pattern)...\n');

% 径向距离 r = sqrt(X^2 + Y^2)
R_dist = sqrt(X.^2 + Y.^2);

% 无量纲衍射角变量 u = k * a * sin(theta) \approx k * a * (r / L)
U = k * R_aperture * (R_dist / L_screen);

% 处理中心奇点 u -> 0 时，2*J1(u)/u -> 1
I_normalized = ones(size(U));
non_zero = (U > 1e-7);
I_normalized(non_zero) = (2 * besselj(1, U(non_zero)) ./ U(non_zero)).^2;

%% 3. 光学特征与瑞利判据指标分析
% 艾里斑第一暗环第一零点：u_01 = 3.8317
% 对应衍射角 sin(theta_01) \approx 1.22 * lambda / (2*a)
u_zero1 = 3.8317;
r_airy_theory = (u_zero1 / (k * R_aperture)) * L_screen; % 理论艾里斑半径 (m)

% 沿 x 轴中心截线提取 1D 光强剖面
I_1D = I_normalized(N_grid / 2, :);

fprintf('=== 波动光学特征指标 ===\n');
fprintf('  激光波长: %.1f nm | 观察距离: %.2f m\n', lambda * 1e9, L_screen);
fprintf('  理论艾里斑半径 (第一暗环): %.3f mm\n', r_airy_theory * 1000);
fprintf('  瑞利角分辨率 (Rayleigh Limit): %.3e rad (%.2f arcsec)\n', ...
        1.22 * lambda / (2 * R_aperture), (1.22 * lambda / (2 * R_aperture)) * 206265);

%% 4. 学术出版级出图 (2D 空间艾里斑云图 + 1D 对数光强衰减剖面)
fprintf('[Step 2] 正在绘制学术级衍射光强空间分布与对数截面图...\n');

fig = figure('Color', 'w', 'Position', [100, 100, 1100, 480], 'Visible', 'off');
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 子图 1: 2D 艾里斑强度伪彩色分布 (采用非线性缩放增强高阶暗环对比度)
nexttile(1);
imagesc(x_vec * 1000, y_vec * 1000, I_normalized.^(0.4)); % 伽马修正便于显示高阶环
colormap(hot);
cbar = colorbar;
cbar.Label.String = 'Normalized Intensity $I/I_0$ (Gamma 0.4)';
cbar.Label.Interpreter = 'latex';
axis image;
xlabel('Screen $X$ (mm)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Screen $Y$ (mm)', 'Interpreter', 'latex', 'FontSize', 11);
title('2D Fraunhofer Diffraction Pattern (Airy Disk)', 'Interpreter', 'latex', 'FontSize', 12);

% 子图 2: 1D 归一化光强截面 (对数坐标展示主极大与次级衍射环)
nexttile(2);
semilogy(x_vec * 1000, I_1D, 'b-', 'LineWidth', 1.8, 'DisplayName', 'Diffraction Profile');
hold on;
xline(r_airy_theory * 1000, 'r--', 'LineWidth', 1.2, 'DisplayName', 'Airy Radius');
xline(-r_airy_theory * 1000, 'r--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
yline(0.0175, 'k:', 'LineWidth', 1.2, 'DisplayName', '1st Secondary Peak');
ylim([1e-5, 1.2]);
xlim([-screen_size*1000, screen_size*1000]);
grid on; box on;
xlabel('Radial Coordinate $r$ (mm)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Intensity $I(r)/I_0$ (Log Scale)', 'Interpreter', 'latex', 'FontSize', 11);
title('Normalized Intensity Radial Cross-Section', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northeast', 'Interpreter', 'latex');

exportgraphics(fig, 'wave_optics_diffraction_result.png', 'Resolution', 300);
fprintf('  [完成] 图表已无损导出至 wave_optics_diffraction_result.png (300 DPI)\n\n');
