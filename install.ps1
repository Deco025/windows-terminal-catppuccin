<#
.SYNOPSIS
    一键应用 Catppuccin Mocha 终端配置。

.DESCRIPTION
    安装 pwsh / oh-my-posh / fastfetch / Maple Mono NF / Terminal-Icons，
    并把仓库里的 settings.json、PowerShell profile、oh-my-posh 主题、fastfetch 配色配置放到位。
    覆盖任何已有文件之前都会先备份成 *.bak-yyyyMMddHHmmss。

.PARAMETER Force
    跳过确认提示。

.EXAMPLE
    .\install.ps1
#>
[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

function Say  ($m) { Write-Host $m -ForegroundColor Cyan }
function Ok   ($m) { Write-Host "  OK   $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "  WARN $m" -ForegroundColor Yellow }

# 覆盖前先备份
function Install-File ($From, $To) {
    $dir = Split-Path $To -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $To) {
        $bak = "$To.bak-$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $To $bak -Force
        Warn "已备份原文件 -> $bak"
    }
    Copy-Item $From $To -Force          # 用 Copy-Item 保持字节原样，避免编码被改写
    Ok $To
}

if (-not $Force) {
    Write-Host ""
    Write-Host "本脚本会覆盖 Windows Terminal 的 settings.json 和 PowerShell 7 的 profile" -ForegroundColor Yellow
    Write-Host "（覆盖前都会自动备份）。继续？[y/N] " -ForegroundColor Yellow -NoNewline
    if ((Read-Host) -notmatch '^[yY]') { Write-Host "已取消"; return }
}

# ---------------------------------------------------------------- 依赖
Say "`n[1/5] 检查 scoop"
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    throw "未找到 scoop。先装 scoop：https://scoop.sh  然后重新运行本脚本。"
}
Ok "scoop 已就绪"

Say "`n[2/5] 安装字体与工具（已装的会自动跳过）"
if (-not (scoop bucket list | Where-Object { $_.Name -eq 'nerd-fonts' })) {
    scoop bucket add nerd-fonts
}
# Maple Mono NF 不含 CJK 字形，中文靠 settings.json 里的字体回退链落到雅黑。
# 想要中文严格 2:1 等宽，把下面这行换成 nerd-fonts/Maple-Mono-NF-CN。
scoop install nerd-fonts/Maple-Mono-NF
scoop install main/pwsh main/oh-my-posh main/fastfetch
Ok "scoop 包安装完毕"

Say "`n[3/5] 安装 Terminal-Icons 模块（装到 PowerShell 7 的模块路径下）"
$pwshExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if ($pwshExe) {
    & $pwshExe -NoProfile -Command "if (-not (Get-Module -ListAvailable Terminal-Icons)) { Install-Module Terminal-Icons -Scope CurrentUser -Force -Repository PSGallery }"
    Ok "Terminal-Icons"
} else {
    Warn "找不到 pwsh，跳过 Terminal-Icons"
}

# ---------------------------------------------------------------- 配置文件
Say "`n[4/5] 放置配置文件"

# Windows Terminal：商店版 / 预览版 / 免安装版
$wtCandidates = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
$wtTarget = $wtCandidates | Where-Object { Test-Path (Split-Path $_ -Parent) } | Select-Object -First 1
if ($wtTarget) {
    Install-File "$root\windows-terminal\settings.json" $wtTarget
} else {
    Warn "没找到 Windows Terminal 的配置目录，跳过 settings.json"
}

# PowerShell 7 profile（注意不是 WindowsPowerShell 那个目录）
Install-File "$root\powershell\Microsoft.PowerShell_profile.ps1" `
             "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

# oh-my-posh 主题：放 ~/.config 下，scoop update oh-my-posh 不会覆盖它
Install-File "$root\oh-my-posh\catppuccin_mocha.omp.json" `
             "$HOME\.config\oh-my-posh\catppuccin_mocha.omp.json"
# fastfetch 配置：内置 Windows 11 logo 换成四色
Install-File "$root\fastfetch\config.jsonc" `
             "$HOME\.config\fastfetch\config.jsonc"

# ---------------------------------------------------------------- conda
Say "`n[5/5] conda"
$condaStd = @(
    $env:CONDA_EXE,
    "$HOME\miniconda3\Scripts\conda.exe",
    "$HOME\anaconda3\Scripts\conda.exe",
    "$env:LOCALAPPDATA\miniconda3\Scripts\conda.exe",
    "$env:ProgramData\miniconda3\Scripts\conda.exe"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if ($condaStd) {
    Ok "conda 在标准路径：$condaStd"
} else {
    Write-Host "  conda 不在标准路径。如果装了 conda，输入 conda.exe 的完整路径（直接回车跳过）：" -ForegroundColor Yellow
    $custom = Read-Host "  路径"
    if ($custom -and (Test-Path $custom)) {
        $localPs1 = "$HOME\.config\pwsh\local.ps1"
        $dir = Split-Path $localPs1 -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $body = "# 本机私有配置，不入库`r`n`$CondaExe = '$custom'`r`n"
        [System.IO.File]::WriteAllText($localPs1, $body, (New-Object System.Text.UTF8Encoding($true)))
        Ok "已写入 $localPs1"
        $condaStd = $custom
    }
}

if ($condaStd) {
    # 关掉 conda 自带的 (base) 前缀，否则会和 oh-my-posh 的 python 段重复显示
    & $condaStd config --set changeps1 False
    Ok "conda changeps1 已关闭"
}

Write-Host ""
Say "完成。新开一个 Windows Terminal 窗口即可（不是新标签 —— 根级 theme 只在新窗口生效）。"
Write-Host ""
