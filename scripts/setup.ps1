# Diary Assistant — 安装脚本 (PowerShell)
# 创建日记目录结构并部署模板文件

param(
    [Parameter(Mandatory=$false)]
    [string]$DiaryPath,

    [Parameter(Mandatory=$true)]
    [string]$UserName,

    [Parameter(Mandatory=$false)]
    [string]$Timezone = "UTC+8 (China Standard)"
)

# ---- 辅助函数 ----
function Write-Step {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ❌ $Message" -ForegroundColor Red
}

# ---- 获取脚本所在路径 ----
$SkillPath = Split-Path -Parent $PSScriptRoot

# ---- 交互式获取日记路径 ----
Write-Host "=== 日记助手 Diary Assistant Setup ===" -ForegroundColor Cyan
Write-Host ""

if (-not $DiaryPath) {
    $defaultPath = "D:\03\日记"
    $input = Read-Host "请输入日记存储路径 (直接回车默认 $defaultPath)"
    if ([string]::IsNullOrWhiteSpace($input)) {
        $DiaryPath = $defaultPath
    } else {
        $DiaryPath = $input
    }
}
$DiaryPath = $DiaryPath.TrimEnd('\')

# 验证路径是否可写
try {
    $testFile = "$DiaryPath\.write-test"
    New-Item -ItemType File -Path $testFile -Force | Out-Null
    Remove-Item -Path $testFile -Force
} catch {
    Write-Error "目录 [$DiaryPath] 不可写入，请检查路径和权限。"
    exit 1
}

# ---- 创建目录结构 ----
Write-Host ""
Write-Host "[1/5] 创建目录结构..." -ForegroundColor Yellow
try {
    New-Item -ItemType Directory -Force -Path "$DiaryPath\raw" | Out-Null
    New-Item -ItemType Directory -Force -Path "$DiaryPath\memory" | Out-Null
    # 预创建当年当月目录
    $nowYear = (Get-Date).ToString("yyyy")
    $nowMonth = (Get-Date).ToString("MM")
    New-Item -ItemType Directory -Force -Path "$DiaryPath\$nowYear\$nowMonth" | Out-Null
    Write-Step "✅ $DiaryPath"
    Write-Step "✅ $DiaryPath\raw\"
    Write-Step "✅ $DiaryPath\memory\"
    Write-Step "✅ $DiaryPath\$nowYear\$nowMonth\"
} catch {
    Write-Error "目录创建失败：$_"
    exit 1
}

# ---- 部署 SOUL.md ----
Write-Host ""
Write-Host "[2/5] 部署 SOUL.md..." -ForegroundColor Yellow
try {
    $soul = Get-Content "$SkillPath\templates\SOUL.md" -Raw
    $soul = $soul -replace '{{USER_NAME}}', $UserName
    Set-Content -Path "$DiaryPath\SOUL.md" -Value $soul
    Write-Step "✅ $DiaryPath\SOUL.md"
} catch {
    Write-Error "SOUL.md 部署失败：$_"
    exit 1
}

# ---- 部署 USER.md ----
Write-Host "[3/5] 部署 USER.md..." -ForegroundColor Yellow
try {
    $user = Get-Content "$SkillPath\templates\USER.md" -Raw
    $user = $user -replace '{{USER_NAME}}', $UserName
    $user = $user -replace '{{DIARY_PATH}}', $DiaryPath
    $user = $user -replace '{{TIMEZONE}}', $Timezone
    Set-Content -Path "$DiaryPath\USER.md" -Value $user
    Write-Step "✅ $DiaryPath\USER.md"
} catch {
    Write-Error "USER.md 部署失败：$_"
    exit 1
}

# ---- 部署 FACT.md ----
Write-Host "[4/5] 部署 FACT.md..." -ForegroundColor Yellow
try {
    $fact = Get-Content "$SkillPath\templates\memory\FACT.md" -Raw
    $fact = $fact -replace '{{DIARY_PATH}}', $DiaryPath
    $fact = $fact -replace '{{TIMEZONE}}', $Timezone
    Set-Content -Path "$DiaryPath\memory\FACT.md" -Value $fact
    Write-Step "✅ $DiaryPath\memory\FACT.md"
} catch {
    Write-Error "FACT.md 部署失败：$_"
    exit 1
}

# ---- 完成 ----
Write-Host ""
Write-Host "[5/5] 配置验证..." -ForegroundColor Yellow

$allOk = $true
if (-not (Test-Path "$DiaryPath\SOUL.md")) { Write-Error "SOUL.md 未找到"; $allOk = $false }
if (-not (Test-Path "$DiaryPath\USER.md")) { Write-Error "USER.md 未找到"; $allOk = $false }
if (-not (Test-Path "$DiaryPath\memory\FACT.md")) { Write-Error "FACT.md 未找到"; $allOk = $false }
if (-not (Test-Path "$DiaryPath\raw")) { Write-Error "raw/ 目录未找到"; $allOk = $false }

if ($allOk) {
    Write-Host ""
    Write-Host "=== 安装完成！===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "下一步操作：" -ForegroundColor Yellow
    Write-Host "  1. 连接消息通道（微信/Telegram）"
    Write-Host "  2. 设置每天 06:00 的自动汇总定时任务"
    Write-Host "  3. 开始发送日记消息！"
    Write-Host ""
    Write-Host "使用示例：" -ForegroundColor Gray
    Write-Host "  你：起床啦"
    Write-Host "  AI：已记下 ✅ 07:30"
} else {
    Write-Host ""
    Write-Error "部分文件部署失败，请检查后重试。"
    exit 1
}
