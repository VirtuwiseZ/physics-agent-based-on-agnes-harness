# physics-agent/register_dsh_addon.ps1 - DeepSeek Harness (DSH) Physics Agent Installer & Environment Inspector
# Pure ASCII implementation to guarantee compatibility across Windows PowerShell 5.1 CP936 / UTF-8.
# Enables users to register the Physics Agent skills into DeepSeek Harness workspace or user profile.

param(
    [string]$ProjectRoot = "",
    [switch]$UserScope = $false,
    [switch]$CheckOnly = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$currentDir = (Get-Location).Path

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Physics Agent - DeepSeek Harness (DSH) Installer       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Locate and verify Project Root
if (-not $ProjectRoot) {
    $candidates = @($currentDir, (Split-Path -Parent $scriptDir), (Split-Path -Parent $currentDir))
    foreach ($cand in $candidates) {
        if ($cand -and (Test-Path (Join-Path $cand "physics-agent")) -and ((Test-Path (Join-Path $cand ".dsh")) -or (Test-Path (Join-Path $cand ".agh")))) {
            $ProjectRoot = $cand
            break
        }
    }
}

if (-not $ProjectRoot -or -not (Test-Path $ProjectRoot)) {
    Write-Host "[ERROR] Could not automatically locate workspace root directory." -ForegroundColor Red
    Write-Host "Please pass the project root explicitly via -ProjectRoot <path>" -ForegroundColor Yellow
    exit 1
}

Write-Host "  -> Project Root: $ProjectRoot" -ForegroundColor Green

# 2. Inspect Python Environment & Scientific Libraries
Write-Host "`n[1/4] Inspecting Python Scientific Computing Libraries..." -ForegroundColor Yellow

$pyCheckCmd = "import sys; print('Python ' + sys.version.split()[0]); " +
              "import sympy; print('  [OK] sympy ' + sympy.__version__); " +
              "import pint; print('  [OK] pint ' + pint.__version__); " +
              "import numpy; print('  [OK] numpy ' + numpy.__version__); " +
              "import scipy; print('  [OK] scipy ' + scipy.__version__); " +
              "import matplotlib; print('  [OK] matplotlib ' + matplotlib.__version__); " +
              "import plotly; print('  [OK] plotly ' + plotly.__version__)"

$pySuccess = $false
try {
    $pyOut = python -c $pyCheckCmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        $pySuccess = $true
        $pyOut | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkCyan }
    } else {
        Write-Host "  [WARN] Some scientific libraries are missing or python returned non-zero." -ForegroundColor Yellow
        $pyOut | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkYellow }
    }
} catch {
    Write-Host "  [WARN] Python command invocation failed. Please check PATH." -ForegroundColor Yellow
}

# 3. Determine Skill Source Directory
Write-Host "`n[2/4] Verifying Skill Assets..." -ForegroundColor Yellow
$srcSkillsDir = Join-Path $ProjectRoot ".dsh\skills"
if (-not (Test-Path $srcSkillsDir)) {
    $srcSkillsDir = Join-Path $ProjectRoot ".agh\skills"
}

if (-not (Test-Path $srcSkillsDir)) {
    Write-Host "[ERROR] Cannot find skills source under .dsh\skills or .agh\skills." -ForegroundColor Red
    exit 1
}

$skillDirs = Get-ChildItem -Path $srcSkillsDir -Directory
Write-Host "  -> Found $($skillDirs.Count) skills under: $srcSkillsDir" -ForegroundColor Green
$skillDirs | ForEach-Object { Write-Host "     * $($_.Name)" }

# 4. Deploy Skills to DSH Workspace and/or User Scope
Write-Host "`n[3/4] Deploying Skills for DeepSeek Harness..." -ForegroundColor Yellow

# Target A: Workspace .dsh/skills
$wsDshSkills = Join-Path $ProjectRoot ".dsh\skills"
if (-not (Test-Path $wsDshSkills)) {
    New-Item -ItemType Directory -Force -Path $wsDshSkills | Out-Null
    Write-Host "  -> Created directory: $wsDshSkills" -ForegroundColor Green
}

if (-not $CheckOnly) {
    foreach ($sd in $skillDirs) {
        $destDir = Join-Path $wsDshSkills $sd.Name
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        }
        $srcFile = Join-Path $sd.FullName "SKILL.md"
        $destFile = Join-Path $destDir "SKILL.md"
        if (Test-Path $srcFile) {
            Copy-Item -Path $srcFile -Destination $destFile -Force
        }
    }
    Write-Host "  [PASS] Synchronized $($skillDirs.Count) skills to workspace .dsh/skills" -ForegroundColor Green
}

# Target B: User profile ~/.dsh/skills (Optional, for cross-workspace global availability)
if ($UserScope) {
    $userDshDir = Join-Path $env:USERPROFILE ".dsh\skills"
    Write-Host "  -> Deploying to user profile: $userDshDir" -ForegroundColor Cyan
    if (-not (Test-Path $userDshDir)) {
        New-Item -ItemType Directory -Force -Path $userDshDir | Out-Null
    }
    if (-not $CheckOnly) {
        foreach ($sd in $skillDirs) {
            $destDir = Join-Path $userDshDir $sd.Name
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Force -Path $destDir | Out-Null
            }
            $srcFile = Join-Path $sd.FullName "SKILL.md"
            $destFile = Join-Path $destDir "SKILL.md"
            if (Test-Path $srcFile) {
                Copy-Item -Path $srcFile -Destination $destFile -Force
            }
        }
        Write-Host "  [PASS] Installed $($skillDirs.Count) skills globally to $userDshDir" -ForegroundColor Green
    }
}

# 5. Run BOM and Header Integrity Verification
Write-Host "`n[4/4] Verifying Skill UTF-8 BOM & Frontmatter Integrity..." -ForegroundColor Yellow
$bomScript = Join-Path $ProjectRoot "physics-agent\hooks\skill_bom_check.py"
if (Test-Path $bomScript) {
    python $bomScript --skills-dir $wsDshSkills
} else {
    Write-Host "  [NOTE] skill_bom_check.py not found, skipping BOM check." -ForegroundColor Yellow
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   DeepSeek Harness Physics Agent Ready!                 " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Quick usage in DSH:"
Write-Host "  Call skill(name=`"physics-agent-orchestrator`") to route physics problems."
Write-Host ""
