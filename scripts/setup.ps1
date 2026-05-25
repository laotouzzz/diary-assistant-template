# Diary Assistant — Setup Script (PowerShell)
# Run this script to initialize the diary directory structure and deploy template files

param(
    [Parameter(Mandatory=$false)]
    [string]$DiaryPath,

    [Parameter(Mandatory=$true)]
    [string]$UserName,

    [Parameter(Mandatory=$false)]
    [string]$Timezone = "UTC+8 (China Standard)"
)

$SkillPath = Split-Path -Parent $PSScriptRoot

Write-Host "=== 日记助手 Diary Assistant Setup ===" -ForegroundColor Cyan
Write-Host ""

# If DiaryPath not provided, prompt user with default
if (-not $DiaryPath) {
    $defaultPath = "D:\03\日记"
    $input = Read-Host "请输入日记存储路径 (直接回车默认 $defaultPath)"
    if ([string]::IsNullOrWhiteSpace($input)) {
        $DiaryPath = $defaultPath
    } else {
        $DiaryPath = $input
    }
}

# Normalize path (ensure no trailing backslash)
$DiaryPath = $DiaryPath.TrimEnd('\')

# 1. Create directory structure
Write-Host "[1/4] Creating directory structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$DiaryPath\raw" | Out-Null
New-Item -ItemType Directory -Force -Path "$DiaryPath\memory" | Out-Null
Write-Host "  ✅ $DiaryPath" -ForegroundColor Green

# 2. Copy and configure SOUL.md
Write-Host "[2/4] Deploying SOUL.md..." -ForegroundColor Yellow
$soul = Get-Content "$SkillPath\templates\SOUL.md" -Raw
$soul = $soul -replace '{{USER_NAME}}', $UserName
Set-Content -Path "$DiaryPath\SOUL.md" -Value $soul
Write-Host "  ✅ $DiaryPath\SOUL.md" -ForegroundColor Green

# 3. Copy and configure USER.md
Write-Host "[3/4] Deploying USER.md..." -ForegroundColor Yellow
$user = Get-Content "$SkillPath\templates\USER.md" -Raw
$user = $user -replace '{{USER_NAME}}', $UserName
$user = $user -replace '{{DIARY_PATH}}', $DiaryPath
$user = $user -replace '{{TIMEZONE}}', $Timezone
Set-Content -Path "$DiaryPath\USER.md" -Value $user
Write-Host "  ✅ $DiaryPath\USER.md" -ForegroundColor Green

# 4. Copy and configure FACT.md
Write-Host "[4/4] Deploying FACT.md..." -ForegroundColor Yellow
$fact = Get-Content "$SkillPath\templates\memory\FACT.md" -Raw
$fact = $fact -replace '{{DIARY_PATH}}', $DiaryPath
$fact = $fact -replace '{{TIMEZONE}}', $Timezone
Set-Content -Path "$DiaryPath\memory\FACT.md" -Value $fact
Write-Host "  ✅ $DiaryPath\memory\FACT.md" -ForegroundColor Green

Write-Host ""
Write-Host "=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Connect your message channel (WeChat / Telegram)"
Write-Host "  2. Set up the daily 06:00 cron task for auto-summary"
Write-Host "  3. Start sending diary entries!"
Write-Host ""
Write-Host "Example usage:" -ForegroundColor Gray
Write-Host "  You: 起床啦"
Write-Host "  AI:  已记下 ✅ 07:30"
