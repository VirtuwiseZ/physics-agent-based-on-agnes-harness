# Notes-for-AI 快速上手与工程防坑指南 (Level 1 Router)

> **归档位置**：`dev-notes/notes-for-ai/_QUICKSTART.md`  
> **服务对象**：面向进入本工作区执行日常代码修改、文档维护与 Git 提交的 AI 智能体  
> **设计范式**：渐进式披露（80% 正常情况阅读本文档即可直接上手；遇到黄色/红色预警信号时，才升级阅读 Level 2 深度规范）。

---

## 一、 轻装作业区：常规 Git 提交四步流 (Happy Path · 80% 场景)

在 `UPC` 分支上完成任何代码或文档修改后，执行规范提交的标准流程如下：

```powershell
# 1. 查看改动状态，核对当前处于 UPC 分支
git status

# 2. 将 Commit 文本写入临时外部文件 (彻底规避 Windows PowerShell 5.1 内联 -m 字符集截断乱码)
# 规范格式: <type>(<scope>): <summary in English or concise Chinese>
# Body: 动宾短语列举实质改动
Set-Content -Path commit_msg.txt -Value @"
docs(upc): <short imperative summary>

- <改动要点 1>
- <改动要点 2>
"@ -Encoding UTF8

# 3. 暂存目标文件并用 -F 提交，随后删除临时文件
git add <affected-files>
git commit -F commit_msg.txt
Remove-Item commit_msg.txt

# 4. 核查工作区状态
git status
```

> ⚠️ **【绝对红线】严禁执行 `git push`**：推送远程仓库的主权完全归人类开发者所有，AI 仅在本地提交。

---

## 二、 轻装作业区：权限拦截与沙盒自愈机制

当在 PowerShell 中执行涉及 `.git` 写入或跨目录操作时，若 DSH 抛出：
`[sandbox: file access denied under workspace-write mode]`

**标准处理原则**：
- **严禁**：在相同的模式下循环重试或换用无意义的指令；
- **正确做法**：单次重试该指令，附加 `sandbox_permissions: "danger-full-access"`，并在 `justification` 中用当前语言清晰说明提权原因（如：“在UPC分支写入.git版本库完成本地代码提交”）。

---

## 三、 轻装作业区：本地 MATLAB R2023b 静默运行

在 Windows 沙盒与无图形界面环境中，运行本地 MATLAB 仿真脚本的标准命令：

```powershell
# 1. 强制重定向配置与遥测缓存至工作区内部，彻底杜绝 mwddux_logging.dll 写入 AppData 触发的 0xc0000005 访问违规崩溃
$env:LOCALAPPDATA = "E:\agnes-harness\.matlab_localappdata"
$env:APPDATA      = "E:\agnes-harness\.matlab_appdata"
$env:MATLAB_PREFDIR = "E:\agnes-harness\.matlab_prefs"

# 2. 推荐通过 addpath 载入脚本目录并直接调用函数/脚本名（保持工作区根目录为当前 pwd）
# 注意：避免使用 run('path/to/file.m')，因 run 会临时切换 pwd 至子目录，可能遭遇沙盒未继承写权限拦截
& "D:\matlab\Matlab 2023b 64bit\bin\matlab.exe" -batch "addpath('physics-agent/knowledge/matlab_upc_guide/02_battle_tested_templates'); template_ballistics_shooting; exit(0);"
```

> **注意（UPC 英文绘图准则）**：MATLAB 内置 LaTeX 解释器不支持中文字符。所有图表中的 `xlabel`、`title`、`legend` 等凡声明 `'Interpreter', 'latex'` 的字符串必须严格使用英文与 LaTeX 数学语法（如 `Downrange $X$ (m)`），同时完全符合 UPC 英文论文出版规范。

---

## 四、 升级触发矩阵 (何时必须升级阅读 Level 2 规范)

只有命中下表中的**升级信号**时，才去定向查阅对应的详细规范，绝不要无事通读：

| 触发信号 (Yellow/Red Triggers) | 风险与问题本质 | 升级查阅目标 (Level 2 详尽规范) |
| :--- | :--- | :--- |
| **提交日志包含多行复杂中文、符号引用或历史改写** | Windows UTF-8 字节被吞，导致 git log 乱码 | [`commit规范与暂存操作指南.md`](commit规范与暂存操作指南.md) |
| **检测到工作区分支异常（如处于 `main` 或 `physics-agent`）** | 存在污染主干或竞赛外代码库的严重风险 | [`分支管理与开发协作规范.md`](分支管理与开发协作规范.md) |
| **调用 `web_fetch` 报 `resolves to a non-public IP`** | 命中代理/VPN TUN 虚拟网卡 Fake-IP 拦截 | [`network_and_vpn_guidelines.md`](network_and_vpn_guidelines.md) |
| **需要获取付费、受限或非文本的物理实验参数** | 商业数据库（CNKI、IEEE）或视频打点资料 | [`需人工查找与整理的数据源.md`](需人工查找与整理的数据源.md) |
| **语言风格拿捏不准，需排查“空话、套话、自吹自擂”** | 确保学术与工程交流的严谨平实 | [`通用语言风格与AI提示词指南.md`](通用语言风格与AI提示词指南.md) |
| **人类提到历史架构（Cordis 插件、1009/1011 任务）** | 原黑客松历史遗留资产，需避免被过时逻辑带偏 | [`历史核心架构决策与演进备忘.md`](历史核心架构决策与演进备忘.md) |
