# Diary Assistant — 安装脚本 (PowerShell)
# 配置文件和工作目录分离，日记输出路径保持干净

param(
    [Parameter(Mandatory=$false)]
    [string]$DiaryOutputPath,

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

$ConfigPath = Split-Path -Parent $PSScriptRoot

Write-Host "=== 日记助手 Diary Assistant Setup ===" -ForegroundColor Cyan
Write-Host ""

# ========== 第1步：获取日记输出路径 ==========
if (-not $DiaryOutputPath) {
    $defaultPath = "D:\我的日记"
    $input = Read-Host "请输入日记输出路径 (只有日记文件会放这里，不含配置文件，回车默认 $defaultPath)"
    if ([string]::IsNullOrWhiteSpace($input)) {
        $DiaryOutputPath = $defaultPath
    } else {
        $DiaryOutputPath = $input
    }
}
$DiaryOutputPath = $DiaryOutputPath.TrimEnd('\')

# 验证路径是否可写
try {
    $testFile = "$DiaryOutputPath\.write-test"
    New-Item -ItemType File -Path $testFile -Force | Out-Null
    Remove-Item -Path $testFile -Force
} catch {
    Write-Error "目录 [$DiaryOutputPath] 不可写入，请检查路径和权限。"
    exit 1
}

# ========== 第2步：创建配置目录结构（跟日记分开） ==========
Write-Host ""
Write-Host "[1/4] 创建配置目录结构..." -ForegroundColor Yellow
try {
    New-Item -ItemType Directory -Force -Path "$ConfigPath\raw" | Out-Null
    New-Item -ItemType Directory -Force -Path "$ConfigPath\memory" | Out-Null
    Write-Step "✅ 配置文件目录: $ConfigPath"
    Write-Step "✅ 暂存目录: $ConfigPath\raw"
    Write-Step "✅ 记忆目录: $ConfigPath\memory"
} catch {
    Write-Error "配置目录创建失败：$_"
    exit 1
}

# ========== 第3步：创建日记输出目录结构（纯日记） ==========
Write-Host ""
Write-Host "[2/4] 创建日记输出目录..." -ForegroundColor Yellow
try {
    $nowYear = (Get-Date).ToString("yyyy")
    $nowMonth = (Get-Date).ToString("MM")
    New-Item -ItemType Directory -Force -Path "$DiaryOutputPath\$nowYear\$nowMonth" | Out-Null
    Write-Step "✅ 日记输出目录: $DiaryOutputPath (纯日记，无配置文件)"
} catch {
    Write-Error "日记输出目录创建失败：$_"
    exit 1
}

# ========== 第4步：部署 SOUL.md（配置文件区，不是日记区） ==========
Write-Host ""
Write-Host "[3/4] 部署配置文件..." -ForegroundColor Yellow
try {
    $soul = Get-Content "$ConfigPath\templates\SOUL.md" -Raw
    $soul = $soul -replace '{{USER_NAME}}', $UserName
    Set-Content -Path "$ConfigPath\SOUL.md" -Value $soul
    Write-Step "✅ $ConfigPath\SOUL.md"
} catch {
    Write-Error "SOUL.md 部署失败：$_"
    exit 1
}

try {
    $user = Get-Content "$ConfigPath\templates\USER.md" -Raw
    $user = $user -replace '{{USER_NAME}}', $UserName
    $user = $user -replace '{{DIARY_PATH}}', $DiaryOutputPath
    $user = $user -replace '{{TIMEZONE}}', $Timezone
    Set-Content -Path "$ConfigPath\USER.md" -Value $user
    Write-Step "✅ $ConfigPath\USER.md"
} catch {
    Write-Error "USER.md 部署失败：$_"
    exit 1
}

try {
    $fact = Get-Content "$ConfigPath\templates\memory\FACT.md" -Raw
    $fact = $fact -replace '{{DIARY_PATH}}', $ConfigPath
    $fact = $fact -replace '{{DIARY_OUTPUT_PATH}}', $DiaryOutputPath
    $fact = $fact -replace '{{TIMEZONE}}', $Timezone
    Set-Content -Path "$ConfigPath\memory\FACT.md" -Value $fact
    Write-Step "✅ $ConfigPath\memory\FACT.md"
} catch {
    Write-Error "FACT.md 部署失败：$_"
    exit 1
}

# ========== 第5步：验证 ==========
Write-Host ""
Write-Host "[4/4] 配置验证..." -ForegroundColor Yellow

$allOk = $true
if (-not (Test-Path "$ConfigPath\SOUL.md")) { Write-Error "SOUL.md 未找到"; $allOk = $false }
if (-not (Test-Path "$ConfigPath\USER.md")) { Write-Error "USER.md 未找到"; $allOk = $false }
if (-not (Test-Path "$ConfigPath\memory\FACT.md")) { Write-Error "FACT.md 未找到"; $allOk = $false }
if (-not (Test-Path "$ConfigPath\raw")) { Write-Error "raw/ 目录未找到"; $allOk = $false }

if ($allOk) {
    Write-Host ""
    Write-Host "=== 安装完成！===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📁 配置文件区：$ConfigPath" -ForegroundColor Gray
    Write-Host "📁 日记输出区：$DiaryOutputPath（只有日记文件，干净）" -ForegroundColor Gray
    Write-Host ""
    Write-Host "下一步操作：" -ForegroundColor Yellow
    Write-Host "  1. 连接消息通道（微信/Telegram）"
    Write-Host "  2. 设置每天 06:00 的自动汇总定时任务（写入 $DiaryOutputPath）"
    Write-Host "  3. 开始发送日记消息！"
} else {
    Write-Host ""
    Write-Error "部分文件部署失败，请检查后重试。"
    exit 1
}
