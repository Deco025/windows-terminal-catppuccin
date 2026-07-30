# =============================================================================
#  PowerShell 7 profile — Catppuccin Mocha
#  安装位置：$PROFILE  ($HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1)
# =============================================================================

# ---------- 本机私有配置（不入库） ----------
# 放机器专有的路径，例如 conda 装在非标准位置时：
#     $CondaExe = 'E:\somewhere\miniconda3\Scripts\conda.exe'
$__local = "$HOME\.config\pwsh\local.ps1"
if (Test-Path $__local) { . $__local }

# ---------- conda ----------
# conda 23.11 的 PowerShell hook 会把空的 $Env:_CE_M / $Env:_CE_CONDA 原样传给 conda.exe。
# PS 5.1 会丢弃空参数，而 PS7 默认的 Standard 模式会真的传一个空参数过去，
# conda 于是收到空的 COMMAND 直接报错，activate / deactivate 全部失效。
# 切回 5.1 的参数传递语义绕开它。conda 升到 24.x 之后可以删掉这一行。
$PSNativeCommandArgumentPassing = 'Legacy'

$__conda = @(
    $CondaExe                                              # local.ps1 指定的优先
    $env:CONDA_EXE
    "$HOME\miniconda3\Scripts\conda.exe"
    "$HOME\anaconda3\Scripts\conda.exe"
    "$env:LOCALAPPDATA\miniconda3\Scripts\conda.exe"
    "$env:ProgramData\miniconda3\Scripts\conda.exe"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if ($__conda) {
    (& $__conda 'shell.powershell' 'hook') | Out-String | Where-Object { $_ } | Invoke-Expression
}

# ---------- 交互式会话判定 ----------
# 管道重定向或 pwsh -c / -f 场景下跳过纯装饰性的东西，
# 否则 fastfetch 的整张信息图会污染脚本输出，PSReadLine 预测还会报错。
$__interactive = (-not [Console]::IsOutputRedirected) -and
                 (-not ([Environment]::GetCommandLineArgs() -match '^-(c|command|f|file|e|encodedcommand)$'))

# ---------- oh-my-posh ----------
# 按优先级找主题：~/.config 下的自定义版（scoop update 不会覆盖它）> oh-my-posh 自带版。
# POSH_THEMES_PATH 由 scoop 设置，但已在运行的进程读不到，所以补一条兜底路径。
$__poshTheme = @(
    "$HOME\.config\oh-my-posh\catppuccin_mocha.omp.json"
    $(if ($env:POSH_THEMES_PATH) { Join-Path $env:POSH_THEMES_PATH 'catppuccin_mocha.omp.json' })
    "$HOME\scoop\apps\oh-my-posh\current\themes\catppuccin_mocha.omp.json"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    if ($__poshTheme) {
        oh-my-posh init pwsh --config $__poshTheme | Invoke-Expression
    } else {
        oh-my-posh init pwsh | Invoke-Expression
    }
}

# ---------- PSReadLine ----------
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -Colors @{
    Command          = '#89B4FA'
    Parameter        = '#94E2D5'
    String           = '#A6E3A1'
    Number           = '#FAB387'
    Operator         = '#F5C2E7'
    Comment          = '#6C7086'
    Error            = '#F38BA8'
    InlinePrediction = '#585B70'
}
Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
if ($__interactive) {
    # 预测补全要求控制台支持 VT，重定向时会报错，故只在交互式下开
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
}

# ---------- Terminal-Icons ----------
if (Get-Module -ListAvailable Terminal-Icons) { Import-Module Terminal-Icons }

# ---------- fastfetch ----------
if ($__interactive -and (Get-Command fastfetch -ErrorAction SilentlyContinue)) { fastfetch }

Remove-Variable __local, __conda, __interactive, __poshTheme -ErrorAction SilentlyContinue
