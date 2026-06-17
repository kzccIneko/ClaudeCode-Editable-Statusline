# Claude Code Statusline — Windows one-click setup
# Usage: powershell -ExecutionPolicy Bypass -File setup.ps1
$ErrorActionPreference = 'Stop'
$dir = "$env:USERPROFILE\.claude"
$scriptPath = "$dir\statusline.ps1"
$cfgPath = "$dir\statusline-config.json"
$settingsPath = "$dir\settings.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Claude Code Statusline Setup (Windows)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Ensure .claude exists ──
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

# ── 2. Copy statusline script ──
$srcScript = Join-Path $PSScriptRoot 'statusline.ps1'
if (Test-Path $srcScript) {
    Copy-Item $srcScript $scriptPath -Force
} else {
    Write-Host "ERROR: statusline.ps1 not found in $(Split-Path $srcScript -Leaf)" -ForegroundColor Red
    Write-Host "Make sure you run this script from the project folder." -ForegroundColor Red
    exit 1
}
Write-Host "[1/3] statusline.ps1 -> $scriptPath" -ForegroundColor Green

# ── 3. Copy config (never overwrite existing) ──
$srcCfg = Join-Path $PSScriptRoot 'statusline-config.json'
if (-not (Test-Path $cfgPath)) {
    if (Test-Path $srcCfg) {
        Copy-Item $srcCfg $cfgPath
        Write-Host "[2/3] statusline-config.json -> $cfgPath" -ForegroundColor Green
    }
} else {
    Write-Host "[2/3] Config already exists, skipped (delete it to reinstall default)" -ForegroundColor Yellow
}

# ── 4. Update settings.json ──
$statusLineCmd = "powershell -NoProfile -NonInteractive -File `"$scriptPath`""
$statusLineConfig = @{ type = "command"; command = $statusLineCmd }

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $settings | Add-Member -MemberType NoteProperty -Name 'statusLine' -Value $statusLineConfig -Force
    $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsPath -Encoding UTF8
} else {
    @{ statusLine = $statusLineConfig } | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsPath -Encoding UTF8
}
Write-Host "[3/3] settings.json updated" -ForegroundColor Green

Write-Host ""
Write-Host "Setup complete! Restart Claude Code to see the statusline." -ForegroundColor Cyan
Write-Host ""
Write-Host "Customize: edit ~/.claude/statusline-config.json" -ForegroundColor Yellow
Write-Host "  - Add/remove/reorder modules in 'line1' and 'line2'"
Write-Host "  - Set 'colors' to false to disable ANSI colors"
Write-Host "  - Available: model, effort, session, git, ctx, cache, tokens, cost, rate5h, rate7d" -ForegroundColor Yellow
