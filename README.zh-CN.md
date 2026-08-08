[English](README.md) | 简体中文

# windows-terminal-catppuccin

一套 Windows Terminal + PowerShell 7 的 Catppuccin Mocha 配置，带一键安装脚本。

![screenshot](assets/screenshot.png)

## 装完你会得到什么

| 层 | 内容 |
|---|---|
| 终端外观 | Catppuccin Mocha 配色、亚克力半透明、无缝标签栏、竖线光标、隐藏滚动条 |
| 字体 | Maple Mono NF（Nerd Font），中文经回退链落到 Microsoft YaHei UI |
| 提示符 | oh-my-posh，显示 git 分支与工作区状态、conda 环境、命令耗时、错误码 |
| Shell | PowerShell 7 + PSReadLine 历史预测（灰字补全 + 列表视图） |
| 杂项 | `ls` 文件类型图标（Terminal-Icons）、新窗口打开时的 fastfetch 信息图（四色 Windows logo） |

「无缝标签栏」的实现只有一行。主题里把活动标签底色设成 `tab.background: "terminalBackground"`，标签与终端背景同色，标签栏和内容区之间的分界线就消失了。

## 先满足这些条件

- Windows Terminal 1.21 或更高。字体回退链和主题里的 `tabRow` / `tab` 背景都从这版开始支持，本配置在 1.24 上验证过。
- scoop 已装好。脚本不会替你装 scoop，检测不到会直接退出。
- conda 可选。脚本会自动探测标准安装路径，找不到就跳过，没装 conda 不影响其他部分。

## 安装

```powershell
git clone https://github.com/Deco025/windows-terminal-catppuccin.git
cd windows-terminal-catppuccin
.\install.ps1
```

脚本会装齐 pwsh / oh-my-posh / fastfetch / Maple Mono NF / Terminal-Icons，把三份配置文件放到位，并关掉 conda 自带的 `(base)` 前缀，否则它会和 oh-my-posh 的 python 段重复显示。覆盖任何已有文件之前都会先备份成 `*.bak-<时间戳>`。

装完要新开一个 Windows Terminal 窗口。根级 `theme` 只在新窗口生效，开新标签不行。

被执行策略拦住时，用下面这条命令运行脚本。

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

不想看确认提示就加 `-Force`。

### 手动安装

| 仓库里的文件 | 放到 |
|---|---|
| `windows-terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| `powershell/Microsoft.PowerShell_profile.ps1` | `$PROFILE`，先在 PowerShell 7 里 `echo $PROFILE` 看实际路径 |
| `oh-my-posh/catppuccin_mocha.omp.json` | `~\.config\oh-my-posh\` |

注意 `$PROFILE` 是 PowerShell 7 的 profile，WindowsPowerShell 5.1 那个目录不生效。主题放 `~/.config` 的独立副本，`scoop update oh-my-posh` 不会把它覆盖掉。

### 让 AI 助手一键装

把仓库链接发给会操作终端的 AI 助手，让它执行下面这段就能完成安装。

```powershell
git clone https://github.com/Deco025/windows-terminal-catppuccin.git
cd windows-terminal-catppuccin
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Force
```

能跑通的前提是机器上已有 scoop 和 Windows Terminal，且 scoop 装在默认的 `%USERPROFILE%\scoop`。前两项不满足时脚本会退出或跳过，第三项不满足时 Windows Terminal 配置里写死的 pwsh 路径会失效。scoop 装在自定义目录、Documents 被 OneDrive 重定向这两类机器，装完可能没有效果，遇到这种情况先检查这两处。

## 常用调整

**透明度**。`settings.json` 里 `profiles.defaults.opacity`，85 是折中值。想更透调到 70，不喜欢亚克力就把 `useAcrylic` 改成 `false`。

**中文严格等宽**。Maple Mono NF 没有 CJK 字形，中文靠 `font.face` 的回退链渲染。想要严格 2 比 1 对齐，用这条命令装带 CJK 的版本。

```powershell
scoop install nerd-fonts/Maple-Mono-NF-CN
```

再把 `font.face` 改成 `"Maple Mono NF CN"`。

**换提示符主题**。`Get-ChildItem $env:POSH_THEMES_PATH` 看 oh-my-posh 自带的一百多套，改 profile 里那行 `--config`。

**fastfetch logo 颜色**。四色 Windows logo 的颜色定义在 `~/.config/fastfetch/config.jsonc` 的 `logo.color` 1 到 4 号位，想换色改这个文件。

**本机专有路径**。profile 会加载 `~/.config/pwsh/local.ps1`，这个文件不入库。conda 装在非标准位置时，在文件里写下面这行。

```powershell
$CondaExe = 'E:\somewhere\miniconda3\Scripts\conda.exe'
```

## 两个值得知道的坑

### conda 在 PowerShell 7 下报 `invalid choice: ''`

从 PowerShell 5.1 换到 7 之后，`conda activate` 可能直接报这个错。

```
conda-script.py: error: argument COMMAND: invalid choice: ''
```

问题出在 conda 的 PowerShell hook，它用下面的方式调用 conda。

```powershell
& $Env:CONDA_EXE $Env:_CE_M $Env:_CE_CONDA shell.powershell activate <env>
```

`_CE_M` 和 `_CE_CONDA` 平时是空字符串。PowerShell 5.1 会把空字符串参数丢弃，PowerShell 7 的 Standard 模式会原样传出去。conda 收到的第一个参数是空字符串，被当成 COMMAND 解析，于是报错。

profile 里已有一行修复，把参数传递切回 5.1 的语义。

```powershell
$PSNativeCommandArgumentPassing = 'Legacy'
```

这行已经写进仓库的 profile，正常安装不用手动加。新版 conda 修过这个问题（24.9 起，PowerShell 7.5 需要 25.1.1 或更高），升级后可以先删掉这行再试。

### `intenseTextStyle` 要设成 `all`，`bright` 会抹平强调

官方 Catppuccin 配色把八个亮色映射成和普通色完全相同的值，`brightRed` 等于 `red`，八个都这样。按传统习惯设成 `"bright"` 时，所有 `ESC[1m` 强调文本，比如 `ls` 的表头、`git status` 的标题行、各种 `--help` 的小节名，会和普通文本长得一模一样。设成 `"all"` 才会用上 Maple Mono NF 的粗体字面。

fastfetch 底部那两行色块看起来只有一行，也是同一个原因。普通色和亮色各有一行，只是颜色完全相同。

## 卸载 / 回滚

`install.ps1` 会把原文件备份成 `*.bak-<时间戳>`，改回去即可。卸载工具用下面几条命令。

```powershell
conda config --set changeps1 True
scoop uninstall pwsh oh-my-posh fastfetch
Uninstall-Module Terminal-Icons
```

## 致谢

[Catppuccin](https://github.com/catppuccin/windows-terminal) · [oh-my-posh](https://ohmyposh.dev) · [Maple Mono](https://github.com/subframe7536/maple-font) · [fastfetch](https://github.com/fastfetch-cli/fastfetch) · [Terminal-Icons](https://github.com/devblackops/Terminal-Icons)
