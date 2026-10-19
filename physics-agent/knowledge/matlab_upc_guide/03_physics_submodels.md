# MATLAB 高频物理底层子函数速查库 (UPC Physics Sub-models)

> **文档属性**：专为 UPC 竞赛物理建模准备的模块化、开箱即用 MATLAB 物理函数库  
> **归档位置**：`physics-agent/knowledge/matlab_upc_guide/03_physics_submodels.md`  
> **使用方法**：在需要对应物理效应时，直接复制对应函数置于 MATLAB 脚本末尾作为局部子函数调用。

---

## 一、 国际标准大气模型 (ISA Atmosphere + Sutherland Viscosity)

**适用题目**：火炮(2025B)、跳伞(2023A)、水弹(2014B)、乒乓球(2012B)、海王星/火星气动减速(2010A/2021A)  
**物理机理**：包含海平面至 20 km 的分层温降、理想气体密度 $\rho(h)$、声速 $c_s(T)$ 与基于萨瑟兰公式的动态粘度 $\mu(T)$。

```matlab
function [rho, c_sound, mu] = isa_atmosphere(H)
    % 输入: H - 海拔高度 (m)
    % 输出: rho - 空气密度 (kg/m^3), c_sound - 声速 (m/s), mu - 动力粘度 (Pa*s)
    
    T0 = 288.15;       % 海平面温度 (K)
    P0 = 101325.0;     % 海平面标准大气压 (Pa)
    L  = -0.0065;      % 对流层垂直温度递减率 (K/m)
    H_trop = 11000.0;  % 对流层顶高度 (m)
    gamma  = 1.4;      % 气体比热比
    R_gas  = 287.05;   % 空气比气体常数 (J/(kg*K))
    g0     = 9.80665;  % 重力加速度 (m/s^2)
    
    H_actual = max(H, 0.0);
    
    if H_actual <= H_trop
        % 对流层 (0 - 11 km)
        T = T0 + L * H_actual;
        P = P0 * (T / T0)^(-g0 / (L * R_gas));
    else
        % 平流层下部 (11 - 20 km, 恒温层)
        T_trop = T0 + L * H_trop;
        P_trop = P0 * (T_trop / T0)^(-g0 / (L * R_gas));
        T = T_trop;
        P = P_trop * exp(-g0 * (H_actual - H_trop) / (R_gas * T_trop));
    end
    
    rho = P / (R_gas * T);
    c_sound = sqrt(gamma * R_gas * T);
    
    % 萨瑟兰公式 (Sutherland's Law) 计算动态粘度 mu(T)
    mu_ref = 1.716e-5; % 参考动力粘度 (Pa*s)
    T_ref  = 273.15;   % 参考温度 (K)
    S_mu   = 110.4;    % 萨瑟兰有效温度常数 (K)
    mu = mu_ref * (T / T_ref)^1.5 * ((T_ref + S_mu) / (T + S_mu));
end
```

---

## 二、 跨音速与超音速球体阻力危机模型 (Transonic Drag Crisis)

**适用题目**：超音速跳伞(2023A)、高速火炮(2025B)、超高速陨石(2021B)  
**物理机理**：球体在马赫数 $M \approx 0.8 \sim 1.2$ 区间由于激波形成产生阻力系数跃升（音障），超音速后阻力系数缓慢衰减。

```matlab
function Cd = drag_sphere_transonic(v, c_sound, rho, d, mu)
    % 输入: v - 相对空气速率 (m/s), c_sound - 声速 (m/s), rho - 密度 (kg/m^3), d - 直径 (m), mu - 粘度 (Pa*s)
    % 输出: Cd - 综合气动阻力系数
    
    M  = v / max(c_sound, 1e-3);
    Re = (rho * v * d) / max(mu, 1e-8);
    
    % 亚音速基础阻力 (结合雷诺数)
    if Re < 1e3
        Cd_sub = 24.0 / max(Re, 1e-3) + 0.44; % 包含斯托克斯过渡
    elseif Re > 3e5
        Cd_sub = 0.15; % 超临界雷诺数阻力危机突降
    else
        Cd_sub = 0.45; % 常规亚音速牛顿阻力区
    end
    
    % 马赫数修正 (激波阻力跃迁)
    if M < 0.7
        Cd = Cd_sub;
    elseif M <= 1.2
        % 跨音速陡升阶段
        Cd = Cd_sub + 0.55 * sin(pi * (M - 0.7) / (1.2 - 0.7));
    else
        % 超音速衰减阶段 (基于修饰牛顿冲击理论)
        Cd = 0.95 / sqrt(M^2 - 1 + 0.2);
        Cd = max(Cd, 0.40);
    end
end
```

---

## 三、 三维马格努斯升力矢量函数 (3D Magnus Effect)

**适用题目**：足球射门(2022B)、乒乓球自旋(2012B)、篮球三分(2011B)  
**物理机理**：旋转球体在气流中受到的横向侧推力 $\vec{F}_M = \frac{1}{2} C_M \rho A r (\vec{\omega} \times \vec{v})$。

```matlab
function F_magnus = magnus_force_3d(omega_vec, v_rel_vec, r, rho)
    % 输入: 
    %   omega_vec - 自旋角速度矢量 [wx; wy; wz] (rad/s)
    %   v_rel_vec - 相对空气速度矢量 [vx; vy; vz] (m/s)
    %   r         - 球体半径 (m)
    %   rho       - 大气密度 (kg/m^3)
    % 输出:
    %   F_magnus  - 三维马格努斯升力矢量 (N)
    
    v_mag = norm(v_rel_vec);
    omega_mag = norm(omega_vec);
    
    if v_mag < 1e-4 || omega_mag < 1e-4
        F_magnus = [0.0; 0.0; 0.0];
        return;
    end
    
    % 无量纲自旋比 (Spin Ratio: Sp = r * omega / v)
    Sp = (r * omega_mag) / v_mag;
    
    % 马格努斯升力系数经验公式 (典型球体)
    Cm = min(0.38, 0.22 * Sp^0.8);
    
    A = pi * r^2;
    % 叉乘方向: omega x v_rel
    cross_dir = cross(omega_vec, v_rel_vec);
    cross_norm = norm(cross_dir);
    
    if cross_norm > 1e-6
        unit_vec = cross_dir / cross_norm;
        F_magnus = 0.5 * rho * A * v_mag^2 * Cm * unit_vec;
    else
        F_magnus = [0.0; 0.0; 0.0];
    end
end
```

---

## 四、 天体万有引力与带带谐项 $J_2$ 摄动场

**适用题目**：天体轨道(2020A/2013A)、小行星偏转(2022A)、人造卫星轨道进动(2010A)  
**物理机理**：包含中心天体球对称引力项以及非完美球体（扁率）引发的 $J_2$ 引力摄动加速度。

```matlab
function a_grav = gravity_with_j2(r_vec, mu_planet, R_planet, J2)
    % 输入: r_vec - 航天器相对于天体质心的空间位置矢量 [x; y; z] (m)
    %       mu_planet - GM 引力常数 (m^3/s^2)
    %       R_planet  - 天体赤道半径 (m)
    %       J2        - 二阶带谐系数 (地球约 1.08263e-3, 纯二体输入 0)
    % 输出: a_grav    - 三维引力加速度矢量 [ax; ay; az] (m/s^2)
    
    x = r_vec(1); y = r_vec(2); z = r_vec(3);
    r = norm(r_vec);
    
    % 理想二体引力
    a_2body = -mu_planet * r_vec / (r^3);
    
    if J2 <= 0.0
        a_grav = a_2body;
        return;
    end
    
    % J2 摄动加速度项
    factor = 1.5 * J2 * mu_planet * (R_planet^2) / (r^5);
    z_ratio = (z / r)^2;
    
    ax_j2 = factor * x * (5 * z_ratio - 1);
    ay_j2 = factor * y * (5 * z_ratio - 1);
    az_j2 = factor * z * (5 * z_ratio - 3);
    
    a_grav = a_2body + [ax_j2; ay_j2; az_j2];
end
```

---

## 五、 空间舱体小孔泄漏与临界壅塞出流 (Choked Orifice Flow)

**适用题目**：空间站微孔漏气减压时间(2024A)  
**物理机理**：当舱内压强与外部真空比超过临界压比时，小孔发生声速临界壅塞（Choked Flow），质量流量仅取决于舱内瞬时温压。

```matlab
function mdot = orifice_leak_flow(P_in, T_in, A_hole, gamma, R_gas, C_discharge)
    % 输入: P_in - 舱内压强 (Pa), T_in - 舱内温度 (K), A_hole - 小孔截面积 (m^2)
    %       gamma - 比热比 (空气 1.4), R_gas - 气体常数 (287.05), C_discharge - 流量系数 (~0.62)
    % 输出: mdot - 质量泄漏率 dm/dt (kg/s)
    
    % 临界出流公式 (真空背景下完全壅塞出流)
    critical_factor = sqrt(gamma / R_gas) * (2 / (gamma + 1))^((gamma + 1) / (2 * (gamma - 1)));
    
    % 质量泄漏速率
    mdot = C_discharge * A_hole * P_in / sqrt(T_in) * critical_factor;
end
```
