# Maintenance record — 2026-09-06

## Baseline and backups

- Original repository baseline: the last commit was dated 2024-11-17; the full commit ID is saved in the backup's `head.txt`.
- The original source contained 650 files, including 383 files of Yazi plugin Git metadata.
- Existing uncommitted Kitty Shift+Enter and Tmux `extended-keys-format csi-u` changes were preserved.
- External backup: `/home/night/.local/state/chezmoi-maintenance/2026-09-06-bl4839hd`. The directory is mode 0700 and original backup files are mode 0600.
- `source-before.tar.gz` stores the original source, `home-before.tar.gz` stores affected local directories, `uncommitted.patch` stores existing changes, and `home-manifest.json` records the baseline.
- The backup was moved from temporary storage to the persistent path. It contains original private configuration and must not be uploaded to a normal Git repository.

To inspect an old configuration, extract it into a separate temporary directory first:

```sh
mkdir -m 700 /tmp/chezmoi-old
tar -xzf /home/night/.local/state/chezmoi-maintenance/2026-09-06-bl4839hd/source-before.tar.gz -C /tmp/chezmoi-old
```

Compare first, then copy back only the source files that truly need rollback.

## Changes implemented

1. Removed nested plugin Git data, Fish state and temporary files, and old backups; tightened `.gitignore` and `.chezmoiignore`. Maintenance tools, documents and logs are not deployed.
2. Synchronized Shell, terminal and Git settings. Added a user-level Zsh entry point, Starship and local FZF integration; optional tools degrade gracefully; fixed broken Zsh editor aliases and wget syntax; avoided duplicate zoxide initialization. Fish no longer forces `TERM` or writes universal state.
3. Synchronized the active LazyVim, Yazi and editor setup. Kept lock files and the Yazi package manifest; removed retired Neovim plugins and the old Yazi `[manager]` section. Yazi `T` keeps a minimal preview and `Alt+t` maximizes it; removed the deprecated bookmarks option. Fixed an orphaned VSCodium comma.
4. Synchronized the Hyprland Lua desktop, Quickshell, Matugen, other terminals, Fastfetch and Fcitx5. Generated colors and shell overrides are preserved; retired hand-written monitor `.conf` files and switchers are no longer managed. nwg-displays Lua files provide the monitor layout. Emoji data was split from the script so Bash syntax checks can parse it.
5. Added read-only checks and temporary restore validation, including dependency versions, plugin revisions and the tmux-tilit patch.

Retired content includes the old AGS `user_options.js`, obsolete Hyprland entry points and shaders, old Kitty themes and search directories, retired Neovim plugins, old Yazi settings, deleted Fish plugin files and Ranger configuration. Existing low-frequency personal settings were retained; replacement software is not installed automatically.

## Credentials and snapshot sources

- The Zsh `GEMINI_API_KEY` assignment was moved to local `secrets.zsh`. It appeared in Git history, so service-side rotation is recommended; history was not rewritten.
- A Claude extension API credential was removed from the repository copy. The original local setting and restricted backup were retained; accounts were not reconfigured automatically.
- The Quickshell About/Welcome page points to `https://github.com/end-4/dots-hyprland`. This repository stores the active local snapshot and cannot verify its exact upstream commit; existing licenses are retained.
- Password commands, runtime password variables, password display entries and translation strings in Quickshell triggered credential heuristics and were reviewed individually. The default `apps.changePassword` value is omitted from personal JSON because the framework supplies it.
- Public SSH keys in Git and signing configuration are retained. Private keys, system keyrings and Git credential files are not included.

## Verification and boundaries

Automated checks cover Shell/Lua/Python syntax, JSON/JSONC/TOML, Git configuration, Yazi plugins and shortcuts, Hyprland modules, Matugen references, deployment exclusions and path boundaries.

Temporary restore ran twice and used `chezmoi verify/status` to check content, permissions, symlinks and idempotence. A generated theme was changed before the second restore to confirm create-only files are not overwritten. JSONC parsing and path-escape regression tests are included.

QML loading, fonts, wallpapers, input methods, suspend, interactive shortcuts, online plugin restoration and language servers require manual acceptance. No desktop session was started and no system configuration was changed. Recorded software versions are a snapshot, not a promise that old packages remain available.

Machine-specific monitor parameters, application paths and wallpaper paths are retained. This repository targets recovery on the same machine. Rime dictionaries, learning data and system-level installation are outside this snapshot.

Python checks still report a few invalid-escape deprecation warnings in old scripts; syntax checks pass. Those upstream snapshots were not rewritten just to remove warnings.

## Final result

- 1,180 managed files passed verification; two temporary restores and generated-theme preservation passed; six checker regression tests passed.
- Zsh reinstall-entry and missing-optional-tool checks passed; an isolated Tmux instance loaded successfully with the Ctrl+A prefix and CSI-u settings; the tmux-tilit patch applies to its recorded revision.
- `git diff --check` passed. Counts and the 21 historical pending items are recorded in [verification.json](verification.json).
- Of 1,179 collected files, two Fcitx files changed between the initial baseline and collection; the collected copies match the final local files. Those two files were not applied back during the original run.
- The original changes remained in the worktree and were not staged, committed or pushed during that maintenance run.
