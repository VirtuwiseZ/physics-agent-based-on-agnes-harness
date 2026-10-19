%% template_param_sweep_heatmap.m - 双参全域网格敏感性扫描与学术等高线/热力相图模版
% 适用题材：所有真题的进阶拓展问（“评估不同风速/仰角/尺寸对结果的影响”、“给出射表或策略推荐”）
% 核心技术：meshgrid 二维参数矩阵生成 + 批量仿真网格遍历 + contourf 等高线注记 + 最优脊线提取 + tiledlayout 出版级出图
% 编写环境：MATLAB R2023b 及以上

clear; clc; close all;

%% 1. 扫描参数域定义 (以火炮射距随发射仰角与炮口初速的双参敏感性为例)
% 自变量 1: 炮口初速度 v0 (m/s)
v0_vec = linspace(250.0, 450.0, 35); 

% 自变量 2: 发射仰角 theta (deg)
theta_vec = linspace(15.0, 75.0, 35);

% 构建 2D 扫描网格
[V0_grid, Theta_grid] = meshgrid(v0_vec, theta_vec);
Range_grid = zeros(size(V0_grid));     % 记录水平落地距离 (m)
FlightTime_grid = zeros(size(V0_grid));% 记录空中飞行时间 (s)

fprintf('====================================================\n');
fprintf('  UPC 双参全域敏感性扫描器 (Parameter Sensitivity Sweep)\n');
fprintf('  参数 1: 炮口初速 [%.1f, %.1f] m/s (共 %d 点)\n', v0_vec(1), v0_vec(end), length(v0_vec));
fprintf('  参数 2: 发射仰角 [%.1f, %.1f] deg (共 %d 点)\n', theta_vec(1), theta_vec(end), length(theta_vec));
fprintf('  网格总计算点数: %d 点\n', numel(V0_grid));
fprintf('====================================================\n\n');

%% 2. 批量网格求值循环 (执行动力学仿真评估)
fprintf('[Step 1] 正在执行全域网格数值求解计算...\n');

% 预热简化物理参数 (含阻力)
g = 9.80665;
k_drag = 0.0012; % 空气阻力折算系数 a_drag = -k * v^2

tic;
for i = 1:size(V0_grid, 1)
    for j = 1:size(V0_grid, 2)
        v0 = V0_grid(i, j);
        th = deg2rad(Theta_grid(i, j));
        
        % 运行前向弹道仿真
        [range_val, t_flight] = quick_ballistic_sim(v0, th, g, k_drag);
        Range_grid(i, j) = range_val;
        FlightTime_grid(i, j) = t_flight;
    end
end
calc_time = toc;
fprintf('  [完成] 网格扫描结束，耗时: %.2f 秒\n', calc_time);

%% 3. 最优参数脊线提取 (Optimal Ridge Line Extraction)
% 在每一个初速下，寻找获得最大射程的最优发射仰角
[max_ranges, max_idx] = max(Range_grid, [], 1);
optimal_thetas = theta_vec(max_idx);

fprintf('\n=== 敏感性相图统计特征 ===\n');
fprintf('  全域最小射程: %.1f m | 全域最大射程: %.1f m\n', min(Range_grid(:)), max(Range_grid(:)));
fprintf('  真空中经典最优角为 45.0 度；在大气阻力下最优仰角偏移至: %.2f ~ %.2f 度\n', ...
        min(optimal_thetas), max(optimal_thetas));

%% 4. 学术论文级双联热力/等高线相图绘制
fprintf('\n[Step 2] 正在绘制学术级热力相图与参数可行域...\n');

fig = figure('Color', 'w', 'Position', [100, 100, 1150, 500]);
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 子图 1: 射程响应云图 + 等高线标注 + 最优仰角脊线
nexttile(1);
[C1, h1] = contourf(V0_grid, Theta_grid, Range_grid, 16, 'LineColor', [0.3 0.3 0.3]);
clabel(C1, h1, 'FontSize', 9, 'Color', 'k', 'LabelSpacing', 200); % 标注等高线数值
colormap(turbo);
cbar1 = colorbar;
cbar1.Label.String = '水平射程 (m)';
cbar1.Label.Interpreter = 'latex';
cbar1.Label.FontSize = 11;

hold on;
% 叠加绘制最优发射角脊线
plot(v0_vec, optimal_thetas, 'w--', 'LineWidth', 2.5, 'DisplayName', '最大射程脊线');
plot(v0_vec, 45 * ones(size(v0_vec)), 'k:', 'LineWidth', 1.5, 'DisplayName', '无阻力参考角 (45°)');

% 标注目标射程 1200m 等高线 (高亮展示)
contour(V0_grid, Theta_grid, Range_grid, [1200, 1200], 'r-', 'LineWidth', 2.5, 'DisplayName', '1200m 目标等高线');

grid on; box on;
xlabel('炮口初速 $v_0$ (m/s)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('发射仰角 $\theta$ (deg)', 'Interpreter', 'latex', 'FontSize', 11);
title('全域射程分布云图与 1200m 命中解集', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northwest', 'Interpreter', 'latex');

% 子图 2: 空中滞空飞行时间云图
nexttile(2);
[C2, h2] = contourf(V0_grid, Theta_grid, FlightTime_grid, 16, 'LineColor', [0.3 0.3 0.3]);
clabel(C2, h2, 'FontSize', 9, 'Color', 'k', 'LabelSpacing', 200);
colormap(turbo);
cbar2 = colorbar;
cbar2.Label.String = '飞行时间 (s)';
cbar2.Label.Interpreter = 'latex';
cbar2.Label.FontSize = 11;

grid on; box on;
xlabel('炮口初速 $v_0$ (m/s)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('发射仰角 $\theta$ (deg)', 'Interpreter', 'latex', 'FontSize', 11);
title('飞行滞空时间分布 (s)', 'Interpreter', 'latex', 'FontSize', 12);

exportgraphics(fig, 'param_sweep_heatmap.png', 'Resolution', 300);
fprintf('  [完成] 双联相图已无损导出至 param_sweep_heatmap.png (300 DPI)\n\n');


%% ===================== 快速仿真子函数 =====================
function [range_x, t_impact] = quick_ballistic_sim(v0, theta, g, k)
    % 简化的非线性阻力动力学: a_x = -k * v * vx, a_y = -g - k * v * vy
    y0 = [0; 0; v0 * cos(theta); v0 * sin(theta)];
    opts = odeset('RelTol', 1e-5, 'AbsTol', 1e-6, 'Events', @ground_hit);
    
    [t, y, te, ye] = ode45(@(t,s) [s(3); s(4); -k*sqrt(s(3)^2+s(4)^2)*s(3); -g-k*sqrt(s(3)^2+s(4)^2)*s(4)], ...
                          [0, 150], y0, opts);
    if isempty(ye)
        range_x = y(end, 1);
        t_impact = t(end);
    else
        range_x = ye(1);
        t_impact = te;
    end
end

function [val, isterminal, dir] = ground_hit(~, s)
    val = s(2); % 高度 y == 0
    isterminal = 1;
    dir = -1;
end
