%% template_multistage_events.m - 多阶段连续分段动力学与事件链式积分模版
% 适用题材：太空跳伞(2023A)、多级火箭分离(2011A/2020A)、蹦床往复弹跳(2023B)、投石机连杆释放(2010B)
% 核心技术：链式 ode45/ode113 + 多级独立事件函数 (Events) + 状态无缝继承 + 连续时序拼接 + 过载(g-force)安全核验
% 编写环境：MATLAB R2023b 及以上

clear; clc; close all;

%% 1. 系统参数定义 (以高空太空跳伞多级伞降为例)
params.m_total   = 190.0;    % 跳伞员 + 宇航服 + 降落伞总质量 (kg)
params.g0        = 9.80665;  % 地表重力加速度 (m/s^2)
params.R_earth   = 6371e3;   % 地球半径 (m)

% 各阶段特征气动迎风面积与阻力系数
% 阶段 1: 自由落体 (Body in Freefall)
params.A_stage1  = 0.8;      % 人体横截面积 (m^2)
params.Cd_stage1 = 1.0;

% 阶段 2: 引导伞/减速稳定伞展开 (Drogue Chute) - 触发阈值: 海拔下降至 15,000 m
params.alt_drogue = 15000.0; % 开伞目标海拔 (m)
params.A_stage2   = 4.5;     % 减速伞面积 (m^2)
params.Cd_stage2  = 1.4;

% 阶段 3: 主伞展开 (Main Parachute) - 触发阈值: 海拔下降至 3,000 m
params.alt_main   = 3000.0;  % 主伞目标海拔 (m)
params.A_stage3   = 38.0;    % 主降落伞面积 (m^2)
params.Cd_stage3  = 1.75;

% 阶段 4: 着陆地表 (Touchdown) - 触发阈值: 海拔下降至 0 m
params.alt_ground = 0.0;

% 初始离舱条件
H0 = 45000.0; % 初始跳伞高度: 45 km (平流层深处)
v0 = 0.0;     % 垂直初速 (m/s)

fprintf('====================================================\n');
fprintf('  UPC 多阶段连续动力学求解器 (Multi-Stage Piecewise ODE)\n');
fprintf('  起始出舱高度: %.1f km | 总质量: %.1f kg\n', H0/1000, params.m_total);
fprintf('  分阶段事件: 自由落体 -> 减速伞(15km) -> 主伞(3km) -> 着陆\n');
fprintf('====================================================\n\n');

%% 2. 多阶段链式连续积分 (Chained ODE Integration)

% 存储全局拼接结果的容器
t_all = [];
y_all = []; % 列1: 高度 y, 列2: 垂直速度 vy (向上为正)
stage_tags = []; % 记录每个时间点属于哪个阶段 (1, 2, 3)

t_current = 0.0;
y_current = [H0; v0];

% ----------------- 阶段 1: 自由落体阶段 -----------------
fprintf('[Stage 1] 自由落体下落中 (目标截断高度: %.0f m)...\n', params.alt_drogue);
opts1 = odeset('RelTol', 1e-8, 'AbsTol', 1e-9, ...
               'Events', @(t,y) event_alt_cross(t, y, params.alt_drogue));
[t1, y1, te1, ye1] = ode45(@(t,y) skydiving_rhs(t, y, params, params.A_stage1, params.Cd_stage1), ...
                           [t_current, t_current + 600], y_current, opts1);

t_all = [t_all; t1];
y_all = [y_all; y1];
stage_tags = [stage_tags; 1 * ones(size(t1))];

% 继承状态传递给阶段 2
t_current = te1;
y_current = ye1';
fprintf('  -> 阶段 1 结束于 t = %.2f s, 速度: %.2f m/s\n', t_current, abs(y_current(2)));

% ----------------- 阶段 2: 减速稳定伞展开阶段 -----------------
fprintf('[Stage 2] 减速伞展开 (目标截断高度: %.0f m)...\n', params.alt_main);
opts2 = odeset('RelTol', 1e-8, 'AbsTol', 1e-9, ...
               'Events', @(t,y) event_alt_cross(t, y, params.alt_main));
[t2, y2, te2, ye2] = ode45(@(t,y) skydiving_rhs(t, y, params, params.A_stage2, params.Cd_stage2), ...
                           [t_current, t_current + 600], y_current, opts2);

% 拼接去除重合端点
t_all = [t_all; t2(2:end)];
y_all = [y_all; y2(2:end, :)];
stage_tags = [stage_tags; 2 * ones(length(t2)-1, 1)];

% 继承状态传递给阶段 3
t_current = te2;
y_current = ye2';
fprintf('  -> 阶段 2 结束于 t = %.2f s, 速度: %.2f m/s\n', t_current, abs(y_current(2)));

% ----------------- 阶段 3: 主降落伞打开至着陆 -----------------
fprintf('[Stage 3] 主降落伞完全展开 (目标截断: 触地 0 m)...\n');
opts3 = odeset('RelTol', 1e-8, 'AbsTol', 1e-9, ...
               'Events', @(t,y) event_alt_cross(t, y, params.alt_ground));
[t3, y3, te3, ye3] = ode45(@(t,y) skydiving_rhs(t, y, params, params.A_stage3, params.Cd_stage3), ...
                           [t_current, t_current + 1800], y_current, opts3);

t_all = [t_all; t3(2:end)];
y_all = [y_all; y3(2:end, :)];
stage_tags = [stage_tags; 3 * ones(length(t3)-1, 1)];

total_time = te3;
v_touchdown = abs(ye3(2));
fprintf('  -> 阶段 3 触地结束于 t = %.2f s (%.1f min), 着陆速度: %.2f m/s\n\n', ...
        total_time, total_time/60, v_touchdown);

%% 3. 过载加速度与生理耐受极限计算 (g-force check)
% 加速度 a = dv/dt = (y(k+1) - y(k-1)) / (t(k+1) - t(k-1))
acc_all = gradient(y_all(:, 2), t_all);
g_force = abs(acc_all) / params.g0;
[max_g, max_g_idx] = max(g_force);

fprintf('=== 安全与人体生理极限评估 ===\n');
fprintf('  最大下落瞬时速度: %.2f m/s (%.1f km/h)\n', max(abs(y_all(:,2))), max(abs(y_all(:,2)))*3.6);
fprintf('  着陆触地撞击速度: %.2f m/s (安全判据: < 7.0 m/s)\n', v_touchdown);
fprintf('  峰值冲击过载:     %.2f g (人体耐受上限: 10~12 g)\n', max_g);
if max_g > 12.0
    warning('警告: 峰值过载 %.2f g 超出常规人体生存安全阈值！需要提前展开减速伞。', max_g);
else
    fprintf('  [合格] 全程过载未超出极限，处于安全耐受范围内。\n');
end

%% 4. 学术论文级分段着色图表绘制
fig = figure('Color', 'w', 'Position', [100, 100, 1100, 500], 'Visible', 'off');
tiled = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% 子图 1: 高度演化与阶段分界
nexttile(1);
idx1 = (stage_tags == 1);
idx2 = (stage_tags == 2);
idx3 = (stage_tags == 3);

plot(t_all(idx1), y_all(idx1, 1)/1000, 'r-', 'LineWidth', 2.2, 'DisplayName', 'Stage 1: Freefall');
hold on;
plot(t_all(idx2), y_all(idx2, 1)/1000, 'b-', 'LineWidth', 2.2, 'DisplayName', 'Stage 2: Drogue Chute');
plot(t_all(idx3), y_all(idx3, 1)/1000, 'g-', 'LineWidth', 2.2, 'DisplayName', 'Stage 3: Main Chute');
yline(params.alt_drogue/1000, 'k--', 'Drogue Deploy', 'Interpreter', 'latex', 'LabelHorizontalAlignment', 'left');
yline(params.alt_main/1000, 'k:', 'Main Deploy', 'Interpreter', 'latex', 'LabelHorizontalAlignment', 'left');
grid on; box on;
xlabel('Time $t$ (s)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Altitude $h$ (km)', 'Interpreter', 'latex', 'FontSize', 11);
title('Multi-Stage Descent Profile', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northeast', 'Interpreter', 'latex');

% 子图 2: 速度剖面与过载冲击曲线 (双轴对比)
nexttile(2);
yyaxis left;
plot(t_all, abs(y_all(:, 2)), 'b-', 'LineWidth', 2.0);
ylabel('Descent Speed $|v|$ (m/s)', 'Interpreter', 'latex', 'FontSize', 11);
grid on;

yyaxis right;
plot(t_all, g_force, 'm-', 'LineWidth', 1.8);
yline(10.0, 'r--', '10g Safety Limit', 'Interpreter', 'latex');
ylabel('Load Factor (g-force)', 'Interpreter', 'latex', 'FontSize', 11);

xlabel('Time $t$ (s)', 'Interpreter', 'latex', 'FontSize', 11);
title('Speed Decay and Deceleration G-force', 'Interpreter', 'latex', 'FontSize', 12);

exportgraphics(fig, 'multistage_result.png', 'Resolution', 300);
fprintf('\n  [完成] 仿真图表已无损导出至 multistage_result.png (300 DPI)\n\n');


%% ===================== 物理子模型与子函数库 =====================

% 1. 动力学控制方程 (RHS): 变重力 + 变密度空气阻力
function dy = skydiving_rhs(~, y, p, A, Cd)
    h = y(1);
    v = y(2); % 向上为正，因此下落时 v < 0
    
    % 1. 随高度衰减的万有引力
    g = p.g0 * (p.R_earth / (p.R_earth + max(h, 0)))^2;
    
    % 2. 随高度衰减的指数大气密度模型 rho(h) = rho0 * exp(-h / H_scale)
    rho0 = 1.225;
    H_scale = 8500.0; % 大气特征标高 (m)
    rho = rho0 * exp(-max(h, 0) / H_scale);
    
    % 3. 气动阻力 F_drag = -0.5 * rho * A * Cd * v * |v|
    % 当 v < 0 时，F_drag > 0 (向上产生阻力)
    F_drag = -0.5 * rho * A * Cd * v * abs(v);
    
    % 4. 垂直加速度 a = F_drag / m - g
    acc = F_drag / p.m_total - g;
    
    dy = [v; acc];
end

% 2. 通用高度截断事件函数
function [val, isterminal, dir] = event_alt_cross(~, y, target_alt)
    val = y(1) - target_alt;
    isterminal = 1; % 触发立刻截断本阶段积分
    dir = -1;       % 仅当下落向下穿过阈值高度时触发
end
