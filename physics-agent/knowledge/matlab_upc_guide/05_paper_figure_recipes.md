# MATLAB 学术论文出版级科研出图秘籍 (UPC Paper Figure Recipes)

> **文档属性**：专为 UPC 竞赛物理论文定制的科研级绘图规范、高频图型模板与排版代码  
> **归档位置**：`physics-agent/knowledge/matlab_upc_guide/05_paper_figure_recipes.md`  
> **核心目标**：确保所有输出图表具备 300+ DPI 无损清晰度、LaTeX 矢量公式标注、零遮挡图例与顶级学术期刊视觉质感。

---

## 一、 出版级科研绘图五大铁律

1. **绝对排版铁律：彻底抛弃 `saveas` / `print`，统一使用 `exportgraphics`**
   - 旧命令 `saveas` 导出的图片分辨率通常只有 72~96 DPI，文字模糊且边界经常被截断；
   - 必须统一使用：
     ```matlab
     exportgraphics(gcf, 'figure_name.png', 'Resolution', 300, 'ContentType', 'image');
     ```
2. **文本字体铁律：全图标签与图例启用 LaTeX 解释器**
   - 标题、X/Y 轴标签、图例、文本批注一律添加 `'Interpreter', 'latex'`；
   - 物理量必须标明国际标准单位，例如：`xlabel('Downrange $x$ ($\mathrm{m}$)', 'Interpreter', 'latex', 'FontSize', 11)`。
3. **语言与字符集铁律：严格纯英文学术标注，严禁在 LaTeX 解释器中混入汉字**
   - UPC 竞赛论文为全英文国际论文，所有图表必须采用纯英文科研命名；
   - MATLAB 内置的 LaTeX 渲染引擎不支持中文字符集，在 `'Interpreter', 'latex'` 字符串中混入汉字将触发 `Warning: Error creating Text` 并可能导致图表生成异常；
   - 图例、坐标轴、数据标注一律使用英文术语 + LaTeX 数学符号（如 `Velocity $v$ (m/s)`、`Load Factor (g-force)`）。
4. **空间布局铁律：使用现代 `tiledlayout` 替代陈旧的 `subplot`**
   - 显式声明 `'Padding', 'compact'` 与 `'TileSpacing', 'compact'`，杜绝子图之间空白浪费与坐标轴挤压。
5. **配色与可读性铁律：杜绝刺眼纯原色，采用学术级色盘**
   - 散点与连续场优先采用感知均匀色盘（`colormap(turbo)` 或 `colormap(viridis)`）；
   - 曲线优先采用高辨识度的深蓝（`#1f77b4`）、砖红（`#d62728`）、暗绿（`#2ca02c`）与琥珀金（`#ff7f0e`）。

---

## 二、 六大高分竞赛图型实战代码模版 (Cookbook)

### Recipe 1: 三维空间弹道 + 地面阴影投影 + 目标靶点标注
适用于火炮外弹道 (2025B)、太空跳伞 (2023A)、足球弧线球 (2022B)。

```matlab
fig = figure('Color', 'w', 'Position', [100, 100, 700, 500], 'Visible', 'off');
ax = axes('Parent', fig);

% 1. 主飞行轨迹
p1 = plot3(x_traj, y_traj, z_traj, 'b-', 'LineWidth', 2.2, 'DisplayName', 'Trajectory');
hold on;

% 2. 地面投影虚线 (Shadow Projection，增强立体空间纵深感)
z_ground = zeros(size(z_traj));
p2 = plot3(x_traj, y_traj, z_ground, 'k--', 'LineWidth', 1.0, 'DisplayName', 'Ground Track');

% 3. 目标靶点标注
p3 = plot3(target_x, target_y, 0, 'rp', 'MarkerFaceColor', 'r', 'MarkerSize', 12, 'DisplayName', 'Target');

grid on; box on; view(45, 30);
xlabel('Downrange $X$ ($\mathrm{m}$)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Crossrange $Y$ ($\mathrm{m}$)', 'Interpreter', 'latex', 'FontSize', 11);
zlabel('Altitude $Z$ ($\mathrm{m}$)', 'Interpreter', 'latex', 'FontSize', 11);
title('3D Flight Trajectory with Crosswind Drift', 'Interpreter', 'latex', 'FontSize', 12);
legend([p1, p2, p3], 'Location', 'northeast', 'Interpreter', 'latex');

exportgraphics(fig, 'fig_3d_trajectory.png', 'Resolution', 300);
```

---

### Recipe 2: 双 Y 轴时序多尺度物理量对比图 (`yyaxis`)
适用于“高度 vs 速度”、“温度 vs 压强”、“能量 vs 过载”等不同量纲物理量的演化对比。

```matlab
fig = figure('Color', 'w', 'Position', [100, 100, 750, 420], 'Visible', 'off');

% 左侧 Y 轴: 速度曲线
yyaxis left;
plot(t, speed, 'b-', 'LineWidth', 2.0);
ylabel('Instantaneous Speed $v(t)$ ($\mathrm{m/s}$)', 'Interpreter', 'latex', 'FontSize', 11);
ax = gca;
ax.YColor = [0.1 0.3 0.8]; % 坐标轴颜色与曲线对齐
grid on;

% 右侧 Y 轴: 瞬时过载加速度 (g-force)
yyaxis right;
plot(t, g_force, 'r--', 'LineWidth', 2.0);
yline(10.0, 'k:', '10g Physiological Limit', 'Interpreter', 'latex', 'LabelHorizontalAlignment', 'left');
ylabel('Load Factor $a/g_0$ ($\mathrm{g}$)', 'Interpreter', 'latex', 'FontSize', 11);
ax.YColor = [0.8 0.1 0.1];

xlabel('Time $t$ ($\mathrm{s}$)', 'Interpreter', 'latex', 'FontSize', 11);
title('Velocity and Deceleration Load Factor Profiles', 'Interpreter', 'latex', 'FontSize', 12);

exportgraphics(fig, 'fig_dual_yaxis.png', 'Resolution', 300);
```

---

### Recipe 3: 二维全域参数扫描热力云图 + 等高线数值标注 (`contourf`)
适用于初速-仰角敏感性相图 (2025B)、足球射门可行域 (2022B)、火星逃逸率分布 (2021A)。

```matlab
fig = figure('Color', 'w', 'Position', [100, 100, 800, 520], 'Visible', 'off');

% 绘制填充等高线
[C, h] = contourf(V0_grid, Theta_grid, Range_grid, 18, 'LineColor', [0.2 0.2 0.2]);
clabel(C, h, 'FontSize', 9, 'Color', 'k', 'LabelSpacing', 220); % 自动沿等高线注记数字
colormap(turbo);
cbar = colorbar;
cbar.Label.String = 'Downrange $R$ ($\mathrm{m}$)';
cbar.Label.Interpreter = 'latex';
cbar.Label.FontSize = 11;

hold on;
% 叠加 1200m 目标关键等高线 (加粗红色高亮)
contour(V0_grid, Theta_grid, Range_grid, [1200, 1200], 'r-', 'LineWidth', 2.5, 'DisplayName', '1200m Target Contour');

% 叠加最优发射角脊线 (白色虚线)
plot(v0_vec, optimal_theta_curve, 'w--', 'LineWidth', 2.2, 'DisplayName', 'Max Range Ridge');

grid on; box on;
xlabel('Muzzle Velocity $v_0$ ($\mathrm{m/s}$)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Launch Angle $\theta$ ($\mathrm{deg}$)', 'Interpreter', 'latex', 'FontSize', 11);
title('Parameter Sensitivity Map and Feasible Domain', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northwest', 'Interpreter', 'latex');

exportgraphics(fig, 'fig_parameter_heatmap.png', 'Resolution', 300);
```

---

### Recipe 4: 蒙特卡洛落点散布 + 95% 协方差置信椭圆 + 目标圆
适用于阵风扰动落点散布 (2025B)、微陨石撞击散布 (2021B)、无人机抗风能力 (2020B)。

```matlab
fig = figure('Color', 'w', 'Position', [100, 100, 750, 500], 'Visible', 'off');

% 绘制落点散点 (透明度 MarkerFaceAlpha 避免重叠死黑)
scatter(x_samples, z_samples, 12, [0.2 0.4 0.8], 'filled', 'MarkerFaceAlpha', 0.4, 'DisplayName', 'Impact Points ($N=2000$)');
hold on;

% 绘制 95% 散布置信椭圆
plot(ellipse_x, ellipse_z, 'r-', 'LineWidth', 2.5, 'DisplayName', '95\% Confidence Ellipse');

% 绘制目标圆与靶心
th = linspace(0, 2*pi, 100);
plot(target_x + R_target*cos(th), target_z + R_target*sin(th), 'k-', 'LineWidth', 2.0, 'DisplayName', 'Target Radius');
plot(target_x, target_z, 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 14, 'DisplayName', 'Target Center');

axis equal; grid on; box on;
xlabel('Downrange $X$ ($\mathrm{m}$)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Crossrange $Z$ ($\mathrm{m}$)', 'Interpreter', 'latex', 'FontSize', 11);
title('Monte Carlo Dispersion with 95\% Confidence Ellipse', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'northeast', 'Interpreter', 'latex');

exportgraphics(fig, 'fig_monte_carlo_ellipse.png', 'Resolution', 300);
```

---

### Recipe 5: 偏微分方程时空演化瀑布图 / 热力图 (`surf` / `mesh`)
适用于空间站微孔泄压 (2024A)、瞬态热传导 (2018B)、行星冷却 (2012A)。

```matlab
fig = figure('Color', 'w', 'Position', [100, 100, 850, 520], 'Visible', 'off');

% 绘制三维曲面
surf(X_mesh, T_mesh, Temperature_mesh, 'EdgeColor', 'none');
colormap(turbo);
cbar = colorbar;
cbar.Label.String = 'Temperature $T$ ($\mathrm{K}$)';
cbar.Label.Interpreter = 'latex';
cbar.Label.FontSize = 11;

view(35, 40); grid on; box on;
xlabel('Position $x$ ($\mathrm{m}$)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Time $t$ ($\mathrm{s}$)', 'Interpreter', 'latex', 'FontSize', 11);
zlabel('Temperature Field $T(x,t)$ ($\mathrm{K}$)', 'Interpreter', 'latex', 'FontSize', 11);
title('Transient Heat Diffusion Spatiotemporal Evolution', 'Interpreter', 'latex', 'FontSize', 12);

exportgraphics(fig, 'fig_pde_surf.png', 'Resolution', 300);
```

---

### Recipe 6: 频域响应与共振峰分析对数曲线 (`semilogx`)
适用于 Sasando 乐器共鸣腔 (2025A)、蹦床耦合振动频谱 (2023B)。

```matlab
fig = figure('Color', 'w', 'Position', [100, 100, 750, 450], 'Visible', 'off');

semilogx(freq_vec, 20*log10(abs(H_response)), 'b-', 'LineWidth', 2.0, 'DisplayName', 'Transfer Function');
hold on;

% 标注共振峰与 -3dB 通带
xline(245, 'r--', 'Fundamental 245 Hz', 'Interpreter', 'latex', 'LabelVerticalAlignment', 'bottom');
xline(490, 'r--', '2nd Harmonic 490 Hz', 'Interpreter', 'latex', 'LabelVerticalAlignment', 'bottom');
yline(-3, 'k:', '-3 dB Bandwidth', 'Interpreter', 'latex');

grid on; box on;
xlim([50, 2000]);
xlabel('Frequency $f$ ($\mathrm{Hz}$, Log Scale)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('Magnitude $20\log_{10}|H(f)|$ ($\mathrm{dB}$)', 'Interpreter', 'latex', 'FontSize', 11);
title('Acoustic Cavity Frequency Response and Resonances', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'southwest', 'Interpreter', 'latex');

exportgraphics(fig, 'fig_frequency_bode.png', 'Resolution', 300);
```
