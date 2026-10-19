%% template_vibration_acoustics.m - 耦合振动模态、声学共鸣与频域响应模版
% 适用题材：乐器腔体共鸣与声学滤波(2025A)、蹦床多刚体耦合弹跳(2023B)、浅水重力波频散(2021B)
% 核心技术：多自由度质量-阻尼-刚度 (M-C-K) 矩阵状态空间化 + 特征值模态分析 (eig) + ode45 时域受迫振动 + FFT 频域提取
% 编写环境：MATLAB R2023b 及以上

clear; clc; close all;

%% 1. 结构与声学物理参数定义 (以三质点耦合振动与共振腔响应为例)
% 质量矩阵 M (kg), 阻尼矩阵 C (N*s/m), 刚度矩阵 K (N/m)
m1 = 2.0; m2 = 3.0; m3 = 1.5;
k1 = 1200.0; k2 = 800.0; k3 = 1500.0; k4 = 1000.0;
c_damp = 1.2; % 比例阻尼系数

M = diag([m1, m2, m3]);
K = [k1 + k2,   -k2,         0;
     -k2,       k2 + k3,    -k3;
      0,        -k3,        k3 + k4];
C = c_damp * eye(3);

fprintf('====================================================\n');
fprintf('  UPC 耦合振动模态与频域响应分析器 (Vibration & Acoustics)\n');
fprintf('  系统自由度: 3 自由度耦合系统\n');
fprintf('====================================================\n\n');

%% 2. 特征值分解与固有固有模态分析 (Modal Analysis)
fprintf('[Step 1] 正在计算系统无阻尼固有圆频率与主振型 (eig)...\n');

[V_modes, D_lambda] = eig(K, M);
omega_n = sqrt(diag(D_lambda)); % 固有圆频率 (rad/s)
freq_hz = omega_n / (2 * pi);   % 固有频率 (Hz)

% 按照频率从小到大排序
[freq_hz, sort_idx] = sort(freq_hz);
omega_n = omega_n(sort_idx);
V_modes = V_modes(:, sort_idx);

fprintf('\n=== 模态特征提取结果 ===\n');
for i = 1:length(freq_hz)
    fprintf('  第 %d 阶模态: 固有频率 = %7.2f Hz (圆频率 omega = %7.2f rad/s)\n', ...
            i, freq_hz(i), omega_n(i));
    fprintf('           标准化主振型 = [%.3f, %.3f, %.3f]^T\n', ...
            V_modes(1,i), V_modes(2,i), V_modes(3,i));
end

%% 3. 时域受迫振动非齐次求解 (ode45 状态空间积分)
fprintf('\n[Step 2] 正在进行时域受迫振动与谐波激励仿真...\n');

% 外加简谐激励力: F(t) = [F0 * sin(omega_drive * t); 0; 0]
drive_freq = freq_hz(1); % 以一阶共振频率施加激励
omega_drive = 2 * pi * drive_freq;
F0_amp = 15.0; % 激励力幅值 (N)

% 构造一阶状态空间动力学矩阵: dY/dt = A * Y + B * u(t)
% 状态 Y = [x1; x2; x3; v1; v2; v3]
invM = inv(M);
A_sys = [zeros(3), eye(3); -invM * K, -invM * C];

Y0 = zeros(6, 1); % 初始静止状态
t_span = [0, 8.0]; % 仿真历时 8 秒

% 使用 ode45 积分求解
[t_vib, Y_vib] = ode45(@(t,y) vibration_rhs(t, y, A_sys, invM, F0_amp, omega_drive), t_span, Y0);

x1 = Y_vib(:, 1);
x2 = Y_vib(:, 2);
x3 = Y_vib(:, 3);

%% 4. 稳态信号离散傅里叶变换 (FFT 频域分析)
fprintf('[Step 3] 提取稳态振荡信号并计算 FFT 频谱...\n');

% 插值到等时间间隔网格供 FFT 使用
Fs = 1000.0; % 采样频率 1000 Hz
t_uniform = linspace(t_vib(1), t_vib(end), round((t_vib(end)-t_vib(1))*Fs));
x1_uniform = interp1(t_vib, x1, t_uniform, 'pchip');

% 选取后半段稳态区间 (消除暂态冲击)
steady_idx = t_uniform >= 3.0;
x_steady = x1_uniform(steady_idx);
N_fft = length(x_steady);

X_fft = fft(x_steady);
fft_mag = abs(X_fft(1:floor(N_fft/2))) / N_fft * 2;
fft_f = (0:floor(N_fft/2)-1) * (Fs / N_fft);

%% 5. 学术出版级出图 (时域多通道轨迹 + 频域幅频响应)
fprintf('[Step 4] 正在绘制学术级振动与频谱图...\n');

fig = figure('Color', 'w', 'Position', [100, 100, 1100, 500]);
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 子图 1: 多质点耦合位移时域演化
nexttile(1);
plot(t_vib, x1 * 1000, 'b-', 'LineWidth', 1.8, 'DisplayName', '质点 1 ($m_1$)');
hold on;
plot(t_vib, x2 * 1000, 'r--', 'LineWidth', 1.8, 'DisplayName', '质点 2 ($m_2$)');
plot(t_vib, x3 * 1000, 'g:', 'LineWidth', 1.8, 'DisplayName', '质点 3 ($m_3$)');
grid on; box on;
xlabel('时间 $t$ ($\mathrm{s}$)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('振动位移 ($\mathrm{mm}$)', 'Interpreter', 'latex', 'FontSize', 11);
title(sprintf('共振激励下各质点时域位移响应 ($f_{\\mathrm{drive}}=%.2f$ Hz)', drive_freq), ...
      'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northeast', 'Interpreter', 'latex');

% 子图 2: 稳态振动 FFT 频域频谱分析
nexttile(2);
plot(fft_f, fft_mag * 1000, 'k-', 'LineWidth', 2.0);
hold on;
xline(freq_hz(1), 'r--', sprintf('模态 1: %.1f Hz', freq_hz(1)), 'Interpreter', 'latex');
xline(freq_hz(2), 'm--', sprintf('模态 2: %.1f Hz', freq_hz(2)), 'Interpreter', 'latex');
xline(freq_hz(3), 'c--', sprintf('模态 3: %.1f Hz', freq_hz(3)), 'Interpreter', 'latex');
xlim([0, max(freq_hz) * 1.5]);
grid on; box on;
xlabel('频率 $f$ ($\mathrm{Hz}$)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('傅里叶振幅谱 ($\mathrm{mm}$)', 'Interpreter', 'latex', 'FontSize', 11);
title('稳态响应离散傅里叶变换 (FFT) 频谱峰值', 'Interpreter', 'latex', 'FontSize', 12);

exportgraphics(fig, 'vibration_acoustics_result.png', 'Resolution', 300);
fprintf('  [完成] 振动图表已无损导出至 vibration_acoustics_result.png (300 DPI)\n\n');


%% ===================== 状态空间受迫振动动力学子函数 =====================
function dY = vibration_rhs(t, Y, A, invM, F0, omega)
    % 简谐外力施加在第 1 个质点上
    F_ext = [F0 * sin(omega * t); 0; 0];
    
    % 加速度激励项: invM * F_ext
    forcing_term = [zeros(3,1); invM * F_ext];
    
    dY = A * Y + forcing_term;
end
