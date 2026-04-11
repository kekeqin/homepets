[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"

if (-not $ProjectRoot) {
    $scriptDirectory = if ($PSScriptRoot) {
        $PSScriptRoot
    }
    else {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    }

    $ProjectRoot = (Resolve-Path (Join-Path $scriptDirectory "..")).Path
}

function Escape-YamlSingleQuoted {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return $Value -replace "'", "''"
}

$desktopRoot = Split-Path $ProjectRoot -Parent
$workspaces = [ordered]@{
    "主控窗口" = $ProjectRoot
    "backend" = Join-Path $desktopRoot "homepets-backend"
    "auth-family" = Join-Path $desktopRoot "homepets-auth-family"
    "home-pet" = Join-Path $desktopRoot "homepets-home-pet"
    "tasks-shop-tests" = Join-Path $desktopRoot "homepets-tasks-shop-tests"
}

foreach ($entry in $workspaces.GetEnumerator()) {
    if (-not (Test-Path -LiteralPath $entry.Value)) {
        throw "缺少工作目录：$($entry.Value)。请先创建 git worktree。"
    }
}

$launchConfigDir = Join-Path $env:APPDATA "warp\Warp\data\launch_configurations"
New-Item -ItemType Directory -Force -Path $launchConfigDir | Out-Null

$launchConfigName = "homepets_codex_parallel.yaml"
$launchConfigPath = Join-Path $launchConfigDir $launchConfigName

$windowBlocks = foreach ($entry in $workspaces.GetEnumerator()) {
    $title = Escape-YamlSingleQuoted -Value $entry.Key
    $cwd = Escape-YamlSingleQuoted -Value $entry.Value
@"
  - tabs:
      - title: '$title'
        layout:
          cwd: '$cwd'
          commands:
            - exec: codex
"@
}

$yamlContent = @"
---
name: HomePets Codex Parallel
active_window_index: 0
windows:
$($windowBlocks -join "`r`n")
"@

Set-Content -LiteralPath $launchConfigPath -Value $yamlContent -Encoding UTF8

Write-Host ""
Write-Host "已生成 Warp Launch Configuration：" -ForegroundColor Green
Write-Host "  $launchConfigPath"
Write-Host ""
Write-Host "对应窗口目录：" -ForegroundColor Cyan
foreach ($entry in $workspaces.GetEnumerator()) {
    Write-Host ("  {0,-18} {1}" -f $entry.Key, $entry.Value)
}

if ($NoLaunch) {
    Write-Host ""
    Write-Host "已跳过启动。你可以稍后手动执行：" -ForegroundColor Yellow
    Write-Host "  Start-Process 'warp://launch/$launchConfigName'"
    exit 0
}

$warpUri = "warp://launch/$launchConfigName"

Write-Host ""
Write-Host "正在尝试启动 Warp 并打开 5 个 Codex 窗口..." -ForegroundColor Green

try {
    Start-Process $warpUri | Out-Null
    Write-Host "已发送启动请求：$warpUri" -ForegroundColor Green
    Write-Host ""
    Write-Host "如果 Warp 没有自动打开，请手动执行以下任一方式：" -ForegroundColor Yellow
    Write-Host "1. 在 PowerShell 执行：Start-Process 'warp://launch/$launchConfigName'"
    Write-Host "2. 打开 Warp -> Command Palette -> Launch Configuration -> 选择 HomePets Codex Parallel"
}
catch {
    Write-Warning "无法直接通过 URI 启动 Warp：$($_.Exception.Message)"
    Write-Host "你仍然可以在 Warp 中手动打开 Launch Configuration：HomePets Codex Parallel" -ForegroundColor Yellow
    exit 1
}
