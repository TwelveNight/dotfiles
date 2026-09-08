# Applied changes after user confirmation

The initial audit remains in [verification.json](verification.json). Its pending-change list is historical. The entries below record what was actually applied; each batch was described and confirmed before deployment.

## 1. VSCodium

- Removed only the orphaned comma on line 671 of `~/.config/VSCodium/User/settings.json`.
- JSONC parsing, content hashes, permissions and `chezmoi verify` passed; VSCodium was not restarted.
- Backup: `~/.local/state/chezmoi-maintenance/applied/vscodium-rqdz6x1l/`.

## 2. Kitty

- Changed theme loading to `globinclude ../../.local/state/quickshell/user/generated/terminal/kitty-theme.conf` and corrected an incorrectly labelled Fish comment.
- Replaced the original absolute glob with a path relative to the Kitty configuration directory because Kitty's `Path.glob` does not accept that absolute pattern.
- Theme paths, source content, permissions and `chezmoi verify` passed; Kitty was not restarted or actively reloaded.
- Backup: `~/.local/state/chezmoi-maintenance/applied/kitty-r6gjw63r/`.

## 3. Tmux

- Changed the sessionx directory from the nonexistent `~/.dotfiles` to `~/.local/share/chezmoi`.
- Removed startup-time TPM and plugin downloads; plugins load only when TPM is already installed.
- Content, permissions and `chezmoi verify` passed. No Tmux command was run and existing sessions were not reloaded.
- Backup: `~/.local/state/chezmoi-maintenance/applied/tmux-6mgjw5jji/`.

## 4. Yazi

- Removed the deprecated bookmarks `save_last_directory` option and kept `last_directory`.
- Removed the old `[manager]` section and kept the current `[mgr]` configuration; `T` toggles the preview and `Alt+t` maximizes or restores it.
- The first apply command was interrupted; a later audit confirmed both files were fully applied and `chezmoi status` was clean.
- Lua, TOML, shortcut uniqueness, permissions and `chezmoi verify` passed. Yazi was not started and plugins were not upgraded.
- Backup: `~/.local/state/chezmoi-maintenance/applied/yazi-2ah_91vn/`.

The rest of the local configuration had not yet been applied at that stage and required separate confirmation.

## 5. Zsh entry point

- Added `~/.zshenv` to set `ZDOTDIR=~/.config/zsh` and load the existing `~/.config/zsh/.zshenv`.
- Content hash, mode 0644, `chezmoi verify` and isolated startup checks passed; no interactive shell was started.
- Backup: `~/.local/state/chezmoi-maintenance/applied/zshenv-_72fbgdk/`.

## 6. Main Zsh configuration

- Updated `~/.config/zsh/.zshrc` to load the base environment and local functions first; missing Zap, FZF, Starship and thefuck remain optional. Zap plugin declarations, Vi insert-mode `jk` and Go paths were kept.
- Content hash, mode 0644, `chezmoi verify` and isolated Zsh startup checks passed; existing terminals were not reloaded.
- An initial check mistook `bindkey` terminal control sequences for an error; the actual exit status was 0 and the Go path check passed.
- Backup: `~/.local/state/chezmoi-maintenance/applied/zshrc-s8d2wedw/`.

## 7. Hyprland Lua migration cleanup (2026-09-06)

- Removed the retired `custom/*.conf` set and the old monitor-layout shortcut.
- Removed four hand-written monitor layouts, their active symlink, and retired `layout.sh` / `workspacerule.sh` switchers.
- Removed inactive nwg-displays `.conf` output files; the Lua entry point imports `monitors.lua` and `workspaces.lua`.
- Kept `hypridle.conf`, `hyprlock.conf`, Hyprlock resources, `monitors.lua`, `workspaces.lua` and `~/.config/nwg-displays/config`.
- Local files were moved, not deleted, to `/home/night/.local/state/chezmoi-maintenance/applied/hypr-conf-retired-BmC23U`. Hyprland was not reloaded.

## 8. Code credentials (2026-09-06)

- Removed the Claude Code API-key environment value from `~/.config/Code/User/settings.json` while retaining its two non-secret environment entries.
- The resulting file matches the chezmoi source; common API-key markers are absent.
- Code was not started or restarted. Backup: `/home/night/.local/state/chezmoi-maintenance/applied/code-settings-6AcA5I`.

## 9. Fish private settings (2026-09-06)

- Updated Fish aliases and startup guards without changing established aliases, PATH entries, input-method variables or the default key-binding mode.
- Moved two private exports to local `~/.config/fish/conf.d/secrets.fish` mode 0600; the managed file optionally loads it and no longer contains those values.
- Fish syntax validation passed; no interactive Fish shell was started. Backup: `~/.local/state/chezmoi-maintenance/applied/fish-XTHZeq`.

## 10. Remaining safe settings (2026-09-06)

- Applied Git formatting without changing parsed configuration keys or values.
- Split fuzzel emoji data from its script into a sibling data file, retaining all 1,928 entries.
- Removed the personal Quickshell `apps.changePassword` field because it equals the framework default.
- Updated Zsh helper paths and missing-tool guards, and moved the Gemini key export to local `~/.config/zsh/utils/secrets.zsh` mode 0600.
- Git, Bash, Zsh and JSON validation passed; applied targets match chezmoi source. No programs or desktop sessions were restarted.
- Backup: `~/.local/state/chezmoi-maintenance/applied/safe-remaining-vmKsOB`.

## 11. Ranger retirement (2026-09-06)

- Removed the Fish `ra` alias and the Zsh `ra` / `ranger_wrapper` entry.
- Moved local Ranger configuration and its source snapshot to `/home/night/.local/state/chezmoi-maintenance/applied/ranger-retired-EH78xF`; removed Ranger configuration from chezmoi.
- The Ranger package remains installed and was not started or uninstalled. Fish and Zsh syntax checks passed.
