# windows-terminal-catppuccin

**[中文](README.md)** | English

A complete Catppuccin Mocha setup for Windows Terminal + PowerShell 7.

![screenshot](assets/screenshot.png)

![demo](assets/demo.gif)

## What's inside

| Layer | Content |
|---|---|
| Terminal look | Catppuccin Mocha palette, acrylic translucency, seamless tab bar, bar cursor, hidden scrollbar |
| Font | Maple Mono NF (Nerd Font), CJK falls back to Microsoft YaHei UI via the font fallback chain |
| Prompt | oh-my-posh with git branch/worktree status, conda env, command duration, exit code |
| Shell | PowerShell 7 + PSReadLine history prediction (inline ghost text + list view) |
| Extras | file-type icons for `ls` (Terminal-Icons), fastfetch info screen on startup |

The "seamless tab bar" comes from `tab.background: "terminalBackground"` in the theme — the active tab's background exactly matches the terminal background, so the divider line between the tab row and the content area disappears.

## Requirements

- Windows Terminal **1.20+** (needed for the font fallback chain); verified on 1.24
- [scoop](https://scoop.sh)
- Optional: conda (auto-detected, skipped if not installed)

## Install

```powershell
git clone https://github.com/Deco025/windows-terminal-catppuccin.git
cd windows-terminal-catppuccin
.\install.ps1
```

The script installs pwsh / oh-my-posh / fastfetch / Maple Mono NF / Terminal-Icons, puts the three config files in place, and disables conda's own `(base)` prefix (otherwise it duplicates oh-my-posh's python segment). **Every existing file is backed up to `*.bak-<timestamp>` before being overwritten.** The real PowerShell 7 profile path is asked from `pwsh` itself, so OneDrive-redirected Documents folders are handled correctly.

After installation, **open a new Windows Terminal window** — the top-level `theme` only takes effect in a new window; a new tab is not enough.

### Manual install

| File in this repo | Destination |
|---|---|
| `windows-terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| `powershell/Microsoft.PowerShell_profile.ps1` | `$PROFILE` (usually `~\Documents\PowerShell\`, **not** `WindowsPowerShell`; under OneDrive if Documents backup is on) |
| `oh-my-posh/catppuccin_mocha.omp.json` | `~\.config\oh-my-posh\` |

The theme lives in `~/.config` instead of overriding oh-my-posh's bundled copy so that `scoop update oh-my-posh` won't clobber it.

## Common tweaks

**Opacity** — `profiles.defaults.opacity` in `settings.json`. 85 is a compromise; drop to 70 for more transparency, or set `useAcrylic` to `false` if you don't like it at all.

**Strictly monospaced CJK** — Maple Mono NF has no CJK glyphs; Chinese text is rendered through the fallback chain in `font.face`. For strict 2:1 CJK alignment, switch to the CN variant:

```powershell
scoop install nerd-fonts/Maple-Mono-NF-CN
```

then change `font.face` to `"Maple Mono NF CN"`.

**Different prompt theme** — `Get-ChildItem $env:POSH_THEMES_PATH` lists the hundred-plus themes bundled with oh-my-posh; edit the `--config` line in the profile.

**Machine-specific paths** — the profile sources `~/.config/pwsh/local.ps1` (not tracked by git). If conda is installed in a non-standard location, put this in it:

```powershell
$CondaExe = 'E:\somewhere\miniconda3\Scripts\conda.exe'
```

## Two pitfalls worth writing down

### 1. conda is completely broken under PowerShell 7

After switching from 5.1 to 7, `conda activate` fails immediately:

```
conda-script.py: error: argument COMMAND: invalid choice: ''
```

The culprit is conda's PowerShell hook, which calls conda like this:

```powershell
& $Env:CONDA_EXE $Env:_CE_M $Env:_CE_CONDA shell.powershell activate <env>
```

`_CE_M` / `_CE_CONDA` only have values when conda runs as `python -m conda`; in a normal install they are **empty strings**. And:

- PowerShell 5.1 **drops** empty-string arguments
- PowerShell 7's default `Standard` argument-passing mode **passes them through as-is**

So `conda.exe` receives `""` as its first argument, parses it as the COMMAND, and errors out.

**Fix**: add one line to the profile to restore the 5.1 semantics.

```powershell
$PSNativeCommandArgumentPassing = 'Legacy'
```

Two other approaches that look plausible but **don't** work:

- `Remove-Item Env:_CE_M, Env:_CE_CONDA` after the hook — works exactly once. `conda activate` re-runs the hook internally, setting both variables back to empty strings.
- Putting `$PSNativeCommandArgumentPassing = 'Legacy'` inside a wrapper function around `Invoke-Conda` — this preference variable is not dynamically scoped for native command invocation, so it has no effect at all.

conda 24.x fixed this upstream; you can delete that line after upgrading.

### 2. `intenseTextStyle` should be `all`, not `bright`

The official Catppuccin palette maps all 8 bright colors to the **exact same** values as the normal ones (`brightRed` = `red` = `#F38BA8`, for all eight).

So with the traditional `"bright"` setting, every piece of `ESC[1m` (bold/emphasis) text in the terminal — `ls` table headers, the title lines of `git status`, section names in `--help` output — looks identical to normal text and the emphasis is completely flattened. Setting it to `"all"` actually uses Maple Mono NF's Bold face.

(That's also why the two rows of color blocks at the bottom of fastfetch look like one row — there really are two rows, normal and bright; they're just identical.)

### 3. fastfetch's builtin logo colors don't work (Windows)

Setting `logo.color` for the builtin `windows11` logo (or the `--logo-color-1` … CLI flags) does **nothing** on the Windows builds of fastfetch 2.66–2.68 — the `$1`–`$4` color placeholders in the logo are never substituted with escape sequences, so the whole logo renders in the default foreground color and the four-color Windows flag comes out flat grey. Module colors (keys, color blocks) work fine; only the logo is affected.

**Workaround**: skip `$N` placeholders and embed ANSI truecolor sequences directly in a logo file. [`fastfetch/win11-logo.txt`](fastfetch/win11-logo.txt) in this repo is a Windows 11 logo with the four colors (`#F25022` / `#7FBA00` / `#00A4EF` / `#FFB900`) baked in — point fastfetch at it as a file logo:

```jsonc
"logo": { "type": "file", "source": "~/.config/fastfetch/win11-logo.txt" }
```

## Uninstall / rollback

`install.ps1` backs up every file it replaces to `*.bak-<timestamp>`; restore those. Additionally:

```powershell
conda config --set changeps1 True
scoop uninstall pwsh oh-my-posh fastfetch
Uninstall-Module Terminal-Icons
```

## License

[MIT](LICENSE)

## Credits

[Catppuccin](https://github.com/catppuccin/windows-terminal) ·
[oh-my-posh](https://ohmyposh.dev) ·
[Maple Mono](https://github.com/subframe7536/maple-font) ·
[fastfetch](https://github.com/fastfetch-cli/fastfetch) ·
[Terminal-Icons](https://github.com/devblackops/Terminal-Icons)
