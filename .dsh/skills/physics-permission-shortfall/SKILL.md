---
name: physics-permission-shortfall
description: '权限缺口与便携环境自愈：处理 DeepSeek Harness 沙盒写拦截、提权申请（danger-full-access）、以及 Python 科学库缺失时的自愈路径。'
---

### Permission Shortfall & Portable Runtime Self-Healing

在执行物理建模、运行门禁脚本或写盘过程中，若遭遇权限拦截或环境依赖缺失，严格按本协议处理，禁止暗自跳步或伪造计算结果：

---

## 一、 DeepSeek Harness 沙盒权限处理 (Sandbox & Permissions)

在 DeepSeek Harness 环境中，命令默认运行在沙盒隔离中：

1. **沙盒策略写阻止（`[sandbox: file access denied under workspace-write mode]`）**：
   - 当命令需要写入工作区外或特定受保护目录（如 `.git` 引用锁定）时，DSH 会返回策略阻止；
   - **合规提权准则**：在 `pwsh` 工具调用中附带 `sandbox_permissions: "danger-full-access"` 并提供一句面向用户的简体中文 `justification` 说明提权原因；
   - 严禁自行变造命令形式绕过沙盒；
2. **Windows 文件 ACL 权限阻断**：
   - 若出现 `SetNamedSecurityInfoW failed (Win32 5)` 等 ACL 权限缺失错误，立即调用 DSH 内置技能：`skill(name="diagnose-windows-sandbox-acl")` 自动诊断与修复目录权限；
3. **用户拒绝或无人应答（Stop-and-Escalate）**：
   - **用户明确拒绝（Kind 1）**：立即停止任务并向用户报告具体阻断节点，等待人工决策；
   - **超时或无人应答（Kind 2）**：向用户提示请求超时，询问是继续授权还是以未应答状态收拢。

---

## 二、 Python 科学计算依赖自愈 (Environment Self-Healing)

在执行任何物理仿真前，需验证环境具备核心科学计算依赖（`numpy`, `scipy`, `sympy`, `pint`, `matplotlib`）：

1. **前置导入冒烟测试**：
   ```powershell
   python -c "import sympy, pint, numpy, scipy, matplotlib; print('READY')"
   ```
2. **便携运行时快路径（Portable Runtime）**：
   - 若系统缺失 Python 或关键科学库，优先检查工作区内置的免安装便携运行时：
     `physics-agent/third_party/portable-runtime/`（包含离线 Python 3.13 解释器与烘焙好的纯本地依赖轮子）；
   - 严禁直接抛出“无 Python 环境”后弃手停滞；
3. **离线依赖安装准则**：
   - 仅当确认系统缺失特定模块时，使用本地离线 wheel 包安装，严禁从不可信外网源随意下载未知二进制文件；
   - 安装完成后必须重新运行冒烟测试，实测确认导入成功方可进入物理计算。
