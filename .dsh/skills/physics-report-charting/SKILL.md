---
name: physics-report-charting
description: '科学图表绘制与离线自包含渲染：支持 9 种静态科研图表（曲线、散点、柱状、二维热力场、3D 空间轨迹/曲面等）与交互图表，严格执行零遮挡外置图例与 100% 离线自包含公式排版。'
---

### Scientific Visualization & Offline Charting (Node 2.7 & Node 4)

科学可视化是揭示物理内在机理的直观窗口。本协议规范图表选型、无遮挡排版及单文件 100% 离线内联。

---

## 1. 触发时机与必画准则

进入 Node 2b 完成数值求解后，若存在以下任一情形，**Node 2.7 绘图为强制必做项**：
1. **多方案 / 多天体 / 多材料对比**（如不同星体引力助推效果对比、多种介质折射率对比）；
2. **参数连续扫描或单调性演化**（如减速量随入射角变化曲线、光谱强度分布）；
3. **微分方程（ODE/PDE）时间或空间演化轨迹**（如相图、带电粒子在磁场中的三维漂移轨迹）。

### 防“水平死线/空白废图”铁律
- 严禁将全域几乎恒定不变的量单独画为一条主曲线；恒定物理基准值（如逃逸速度、安全阈值）必须通过 `thresholds` 字段作为水平/垂直参考虚线叠加；
- 若数据跨越数个数量级，必须设置对数坐标轴（`axes.y.scale = "log"`），防止微弱特征被线性轴压缩成贴地死线。

---

## 2. 9 种科研级静态图表选型与配置

在 `problem_state.json` 的 `numerical_artifacts.figures` 中声明图表：

1. **`curve` / `scatter`（连续响应与散点分布）**：支持多条 `series` 对比，通过 `thresholds: [{"axis": "y", "value": 15.59, "label": "入轨需求"}]` 叠加基准虚线；
2. **`bar`（离散多方案/天体定量对比）**：传入 `categories` 与 `series`，柱顶自动标注数值；
3. **`heatmap`（二维连续参数场与相关性矩阵）**：
   - 物理扰动发散量（正负速度差、温度差）：开启 `diverging: true` 启用以 0 为中心的双斜率归一；
   - 跨数量级物理场（光通量、辐射强度）：设置 `norm: "log"`；
   - 空间等值线：设置 `heatmap_style: "contourf"` 自动绘制等高线并内联数值标签；
   - 参数相关性矩阵：开启 `annot: true` 在网格中心标注数值；
4. **`3d_curve`（空间三维运动轨迹）**：每个 series 包含等长 `x, y, z`；支持 `ground_projection: true` 在底面投射半透明灰色投影；
5. **`3d_surface`（三维势能曲面/能量景观/波函数）**：传入二维标量网格 `grid`，支持底部切片投影；
6. **`boxplot` / `error_bar` / `interval_highlight`（统计分布与误差棒）**。

### 图例零遮挡铁律 (Zero-Occlusion Legend Rule)
- 在所有 2D 与 3D 图表中，**严禁图例框压盖数据曲线、散点或初始段**；
- 绘制 $\ge 3$ 条曲线时，必须启用外挂式布局（`legend_position="outside"`），画布 100% 留给数据；
- 在 HTML 报告中采用外置独立 Flex 胶囊图例栏展示图例。

---

## 3. 生成与引用

1. **执行绘图生成**：
   ```powershell
   python physics-agent/hooks/make_report_figures.py --state physics-agent/runtime/<task-slug>/problem_state.json --out-dir physics-agent/runtime/<task-slug>/figures
   ```
2. **报告正文引用**：在 Node 3 Markdown 正文中以独立成行的 `{{figure: <figure_id>}}` 占位符嵌入图表。

---

## 4. Node 4：单文件 100% 离线自包含内联规范 (E1 Invariant)

- **严禁依赖外部 CDN 与跨域 fetch**：
  生成的单文件 HTML 必须将 **KaTeX 数学排版 CSS/JS 引擎**以及所有矢量图表（Base64 SVG/PNG）完全内嵌；
- 用户在完全断网环境下本地双击 HTML，分式、上标、积分、希腊字母与高精度图表必须 100% 正常渲染，绝对禁止将裸露的 `$...$` 或死链图片暴露给用户。
