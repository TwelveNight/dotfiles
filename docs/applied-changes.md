# 用户确认后的应用记录

初次整理的验证结果保留在 `verification.json`，其中待应用清单是当时的历史记录。实际应用进度记录如下，每批均先说明准确差异并取得用户确认。

## 第 1 次：VSCodium

- 用户确认后，仅删除 `~/.config/VSCodium/User/settings.json` 第 671 行孤立逗号。
- JSONC、内容哈希、文件权限和 chezmoi verify 检查通过；没有重启 VSCodium。
- 备份：`~/.local/state/chezmoi-maintenance/applied/vscodium-rqdz6x1l/`。

## 第 2 次：Kitty

- 用户确认后，将主题加载改为 `globinclude ../../.local/state/quickshell/user/generated/terminal/kitty-theme.conf`；把误写为 Fish 的注释改为通用 Shell 注释。
- 修正了仓库初版 globinclude 使用绝对路径的问题：本机 Kitty 使用的 Path.glob 不接受绝对模式，因此使用从 Kitty 配置目录出发的相对路径。
- 主题路径、源文件与本机内容、权限和 chezmoi verify 检查通过；没有重启或主动重载 Kitty。
- 备份包含修改前本机文件和仓库文件：`~/.local/state/chezmoi-maintenance/applied/kitty-r6gjw63r/`。

## 第 3 次：Tmux

- 用户确认后，将 sessionx 的目录从不存在的 `~/.dotfiles` 改为 `~/.local/share/chezmoi`。
- 移除启动时自动下载 TPM 和插件的命令，改为仅在 TPM 已安装时加载；本机 TPM 已安装。
- 文件内容、权限和 chezmoi verify 检查通过；应用过程中没有执行 Tmux 命令，也没有重载现有会话。
- 备份：`~/.local/state/chezmoi-maintenance/applied/tmux-6mgv5jji/`。

## 第 4 次：Yazi

- 用户确认后，删除 bookmarks 插件已弃用的 `save_last_directory` 选项，保留新的 `last_directory` 设置。
- 删除旧版 `[manager]` 配置段，保留当前 `[mgr]` 配置；`T` 用于显示或隐藏预览，`Alt+t` 用于最大化或恢复预览。
- 应用命令返回时对话被中断；恢复后检查确认两个文件均已完整应用，回执已成功写入，chezmoi status 无差异。
- Lua、TOML、快捷键唯一性、权限和 chezmoi verify 检查通过；没有启动 Yazi 或升级插件。
- 备份：`~/.local/state/chezmoi-maintenance/applied/yazi-2ah_91vn/`。

其余本机配置尚未应用，需继续逐次确认。

## 第 5 次：Zsh 启动入口

- 用户确认后，新增 `~/.zshenv`：设置 `ZDOTDIR=~/.config/zsh`，再加载现有 `~/.config/zsh/.zshenv`。
- 内容哈希、0644 权限、chezmoi verify 和独立 Zsh 启动入口检查通过；没有启动交互式 Shell。
- 备份回执：`~/.local/state/chezmoi-maintenance/applied/zshenv-_72fbgdk/`。

## 第 6 次：Zsh 主启动配置

- 用户确认后，更新 `~/.config/zsh/.zshrc`：先加载基础环境与本地函数，缺少 Zap、FZF、Starship、thefuck 等可选工具时继续启动；保留 Zap 插件列表、Vi 插入模式 `jk` 和 Go 路径。
- 内容哈希、0644 权限、chezmoi verify 和隔离 Zsh 启动检查通过；没有重载现有终端或启动交互式 Shell。
- 首次验证把 `bindkey` 写出的终端控制序列误判为异常输出；实际退出状态为 0，随后以退出状态和 Go 路径完成复核。
- 备份回执：`~/.local/state/chezmoi-maintenance/applied/zshrc-s8d2wedw/`。

## 7. Hyprland Lua migration cleanup (2026-09-06)

- Removed the retired `custom/*.conf` configuration set and the old monitor-layout shortcut.
- Removed four hand-written monitor layouts, their active symlink, and the retired `layout.sh` / `workspacerule.sh` switchers.
- Removed inactive nwg-displays `.conf` output files; the Lua entry point imports `monitors.lua` and `workspaces.lua`.
- Kept `hypridle.conf`, `hyprlock.conf`, `hyprlock` resources, `monitors.lua`, `workspaces.lua`, and `~/.config/nwg-displays/config`.
- Local files were moved, rather than deleted, to `/home/night/.local/state/chezmoi-maintenance/applied/hypr-conf-retired-BmC23U`. Hyprland was not reloaded.

## 8. Code credentials (2026-09-06)

- Removed the Claude Code API-key environment value from `~/.config/Code/User/settings.json` while retaining its two non-secret environment entries.
- The resulting file exactly matches the chezmoi source; common API-key markers are absent.
- Code was not started or restarted. Backup: `/home/night/.local/state/chezmoi-maintenance/applied/code-settings-6AcA5I`.

## 9. Fish private settings (2026-09-06)

- Updated Fish aliases and startup guards without changing the established aliases, PATH entries, input-method variables, or default key-binding mode.
- Moved two private environment exports to the local `~/.config/fish/conf.d/secrets.fish` with mode `0600`; the managed file optionally loads it and no longer contains those values.
- Fish syntax validation passed; no interactive Fish shell was started. Backup: `/home/night/.local/state/chezmoi-maintenance/applied/fish-XTHZeq`.

## 10. Remaining safe settings (2026-09-06)

- Applied Git formatting with no parsed configuration-key or value change.
- Split the existing fuzzel emoji data from its script into a sibling data file, retaining all 1,928 entries.
- Removed the Quickshell personal `apps.changePassword` field because it equals the framework default.
- Updated Zsh helper paths and missing-tool guards, and moved the Gemini key export to local `~/.config/zsh/utils/secrets.zsh` with mode `0600`.
- Git, Bash, Zsh, and JSON validation passed; the applied targets exactly match chezmoi source. No programs or desktop session were restarted. Backup: `/home/night/.local/state/chezmoi-maintenance/applied/safe-remaining-vmKsOB`.

## 11. Ranger retirement (2026-09-06)

- Removed the Fish `ra` alias and the Zsh `ra`/`ranger_wrapper` entry.
- Moved the local Ranger configuration and source snapshot to `/home/night/.local/state/chezmoi-maintenance/applied/ranger-retired-EH78xF`; removed the Ranger configuration from chezmoi.
- The Ranger package remains installed and was not started or uninstalled. Fish and Zsh syntax checks passed.
