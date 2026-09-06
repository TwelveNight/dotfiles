# dotfiles

使用 chezmoi 管理本机 Arch Linux 配置，目标是日常维护和重装恢复。当前基线为 2026-09-06；维护记录见 [docs/maintenance.md](docs/maintenance.md)。

## 管理内容

- Shell 与开发工具：Zsh、Fish、Bash、Starship、Kitty、Tmux、Git、Lazygit、LazyVim/Neovim、Yazi、Code、VSCodium、IdeaVim、VsVim。
- 桌面：Hyprland Lua 配置、Hypridle/Hyprlock、Quickshell/illogical-impulse 个人维护配置、Matugen 模板、Ghostty、Foot、WezTerm、Fastfetch、Fcitx5。
- 保留本机仍存在的 Neofetch、手势配置和个人脚本。

插件 Git 数据、历史、缓存、凭据、安装标记和自动生成的主题不作为普通配置管理。Quickshell 以本机现用快照为起点独立维护，包含已有资源和许可证；它没有可验证的上游提交号，不自动拉取或覆盖上游。具体范围和流程见 [Quickshell 维护说明](docs/quickshell-maintenance.md)。

## 检查仓库

依赖 Python 3.11+、chezmoi、Git、Bash、Zsh、Fish 和 `luac`（Arch 的 `lua` 包）。

```sh
cd "$(chezmoi source-path)"
python scripts/check.py
python scripts/check.py --restore
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s scripts -p 'test_*.py'
```

检查不会写入本机配置。`--restore` 只在临时目录部署，隔离 HOME、XDG 路径、chezmoi 状态和缓存，禁用脚本及 external 下载。它检查两次恢复、内容/权限/链接、主题保留、语法及主要引用关系，不启动桌面或插件安装器。Python 旧脚本的弃用警告单独列出；通过静态检查不代表桌面和所有插件已实机验收。

## 重装恢复顺序

1. 安装 chezmoi、Git、Python 和常用应用。先参考 [软件版本基线](docs/software-versions.txt)，避免恢复时同时升级配置与依赖。
2. 克隆配置，先检查，不直接使用 `init --apply`：

   ```sh
   chezmoi init TwelveNight
   cd "$(chezmoi source-path)"
   python scripts/check.py --restore
   chezmoi diff
   ```

3. 按组恢复。以下命令会写入实际配置，应在检查差异之后执行：

   ```sh
   chezmoi apply ~/.zshenv ~/.config/zsh ~/.config/fish ~/.bashrc ~/.config/starship.toml
   chezmoi apply ~/.config/kitty ~/.config/tmux ~/.config/git ~/.config/lazygit ~/.local/scripts
   chezmoi apply ~/.config/nvim ~/.config/yazi
   ```

   Code、VSCodium 和其他编辑器可按需定向恢复。Git 配置保留个人身份、SSH 签名及 1Password/gh 相关设置；重新登录这些工具后再验证签名，不复制凭据文件。

4. 恢复插件，保持锁定版本：

   - **Neovim**：保留 `lazy-lock.json`，通过 Lazy 的 `restore` 恢复锁定版本。首次启动需要联网引导 `lazy.nvim`，之后执行 `:Lazy restore`；不使用 `:Lazy update`。
   - **Yazi**：运行 `ya pkg install`，按 `package.toml` 中的 revision/hash 恢复。不要用 `ya pkg upgrade` 代替恢复。
   - **Zap / TPM**：安装仓库及插件的来源、目标路径和完整提交号保存在 [plugin-sources.json](docs/plugin-sources.json)。在首次启动 Shell/Tmux 前逐项克隆到记录路径并 checkout 对应 revision；这样启动时不会因插件缺失拉取最新版本。示例：

     ```sh
     # 用清单中对应条目的 origin、目标路径和 revision 替换参数。
     git clone --no-checkout '<origin>' '<目标路径>'
     git -C '<目标路径>' checkout --detach '<revision>'
     ```

     `tmux-tilit` 有个人修改；checkout 清单中的提交后恢复补丁：

     ```sh
     git -C ~/.config/tmux/plugins/tmux-tilit apply --check "$(chezmoi source-path)/docs/patches/tmux-tilit.patch"
     git -C ~/.config/tmux/plugins/tmux-tilit apply "$(chezmoi source-path)/docs/patches/tmux-tilit.patch"
     ```

     日常的 TPM 安装/更新快捷键会联网，更新后需单独检查版本差异。Zsh 在 Zap 未安装时仍能加载基础设置。

5. 补回私密配置。将 API Key 放在本机 `~/.config/zsh/utils/secrets.zsh`，设置 `chmod 600`；文件由 Zsh 可选加载，已被两套忽略规则排除。Fish 可用 `~/.config/fish/conf.d/secrets.fish`。在这些文件中自行填写真实值，不要把它们添加到仓库。

   Code 的 Claude 扩展凭据请通过环境或扩展的本机凭据设置提供；仓库保留非凭据设置。Quickshell 的 API 凭据使用其系统钥匙串功能，重装后重新设置。

6. 恢复桌面前，安装匹配版本的 Hyprland、Quickshell、Qt6 QML 模块、Matugen、illogical-impulse 依赖包组、Hypridle、Hyprlock、Fuzzel、剪贴板和音频工具；具体本机版本见清单。Fcitx5 配置包含拼音与 Rime，需相应引擎；个人 Rime 词库和学习数据不在本仓库。

   ```sh
   chezmoi diff ~/.config/hypr ~/.config/quickshell ~/.config/illogical-impulse ~/.config/matugen
   chezmoi apply ~/.config/hypr ~/.config/quickshell ~/.config/illogical-impulse ~/.config/matugen
   chezmoi apply ~/.config/ghostty ~/.config/foot ~/.config/wezterm ~/.config/fastfetch ~/.config/fcitx5
   ```

   检查显示器名称/排列及硬件专用设置后，再进入桌面会话。首次从 Quickshell 设置界面选择一个存在的壁纸并生成主题；私人壁纸、字体文件和系统级服务设置需另外恢复。Kitty 在生成主题缺失时使用默认配色；Hyprland/Hyprlock/Ghostty 有仅创建一次的初始文件，已有生成内容不会被覆盖。

7. 人工验证显示器、快捷键、锁屏/休眠、输入法、剪贴板、字体、Yazi 预览及 Neovim 语言工具。仓库里的网络/引导/NVIDIA 修复脚本只供按需查看，不属于恢复时自动执行的步骤。

## 日常维护与回滚

修改本机配置后，定向同步并检查：

```sh
chezmoi add ~/.config/tmux/tmux.conf
cd "$(chezmoi source-path)"
git diff --stat
git diff -- private_dot_config/tmux/tmux.conf
python scripts/check.py --restore
```

`chezmoi add` 会以本机文件替换对应源文件，需先确认源仓库没有尚待应用的修改。对于已移出凭据的 Shell/编辑器配置，先手工合并或清理私密值，避免重新导入。不要递归 `add ~/.config` 或无差别执行 `re-add`。

修改仓库后，先用 `chezmoi diff <文件>` 查看部署差异，再 `chezmoi apply <文件>`。插件升级另开一次变更，记录锁文件和本地补丁；停用工具时用 `chezmoi forget <路径>` 退出管理（保留本机文件），然后检查 Git 差异。

每次应用前备份受影响的本机文件。已提交版本可先用 `git show <提交>:<源文件>` 查看，再只恢复需要的文件；未提交变更使用本次的仓库外备份，位置和操作示例见维护记录。恢复前确认是否有新的个人修改，避免用全仓库回滚覆盖它们。
