# 2026-09-06 维护记录

## 基线与备份

- 仓库原始基线：最后一次提交日期为 2024-11-17；完整提交号保存在备份中的 `head.txt`。
- 原始源仓库 650 个文件，其中 383 个为 Yazi 插件 Git 内部数据。
- 操作前已有 Kitty Shift+Enter 与 Tmux `extended-keys-format csi-u` 两项未提交改动；更新后的配置保留两项设置。
- 仓库外备份：`/home/night/.local/state/chezmoi-maintenance/2026-09-06-bl4839hd`。目录权限 0700，原始备份文件权限 0600。
- `source-before.tar.gz` 保存修改前源文件；`home-before.tar.gz` 保存相关本机目录；`uncommitted.patch` 保存原有改动；`home-manifest.json` 记录本机内容、权限和链接基线。
- 备份已从临时目录移到上述持久目录，重启后仍可回滚。其中含原始私密配置，不应上传到普通 Git 仓库。

需要查看旧配置时先解压到另外的临时目录，例如：

```sh
review_dir=$(mktemp -d)
tar -xzf /home/night/.local/state/chezmoi-maintenance/2026-09-06-bl4839hd/source-before.tar.gz -C "$review_dir"
# 比对后，只把确实需要回滚的源文件复制回仓库。
```

## 已实施变更

1. 清理嵌套插件 Git 数据、Fish 状态/临时文件和旧备份；补上 `.gitignore`，重新整理 `.chezmoiignore`。维护工具、文档和日志不部署。
2. 同步 Shell、终端及 Git。新增用户级 Zsh 启动入口，补管 `.zshenv`、Starship 和本地 FZF 集成；可选工具缺失时降级；纠正 Zsh 编辑别名的失效路径及 wget 别名写法，避免重复初始化 zoxide。Fish 不再强制 TERM 或写入 universal 路径状态。
3. 同步现用 LazyVim、Yazi 和编辑器。保留 Lazy 锁文件与 Yazi 包清单；移除不再使用的 Neovim 插件目录和 Yazi `[manager]` 段。Yazi `T` 保留最小化预览，`Alt+t` 用于最大化预览；去掉 bookmarks 已弃用选项。修正 VSCodium 配置的孤立逗号。
4. 同步 Hyprland Lua 桌面与 Quickshell、Matugen 等依赖配置，补管其他终端、Fastfetch 和 Fcitx5。仅缺失时创建主题初始文件，保留本机生成的配色和 shell overrides；旧手写显示器 `.conf` 和切换脚本退出管理，由 nwg-displays 生成的 Lua 文件提供显示器布局。Emoji 菜单脚本的内嵌数据分离成 `.txt`，使脚本能够完整接受 Bash 语法检查。
5. 增加只读检查入口及临时恢复验证，记录恢复步骤、依赖版本、插件提交号和 tmux-tilit 本地补丁。

AGS 旧 `user_options.js`、旧 Hyprland 入口/着色器、Kitty 旧主题及搜索目录、旧 Neovim 插件、旧 Yazi 配置、Fish 已删除插件文件和 Ranger 配置退出管理。仍存在的低频个人配置继续保留；不自动安装替代软件。

## 凭据与快照来源

- Zsh 中的 `GEMINI_API_KEY` 从源文件移出，改为可选加载本机 `secrets.zsh`。已经确认对应赋值进入过 Git 历史，建议在服务端轮换；本轮未改写历史。
- Code 的 Claude 扩展环境配置中另有一项 API 凭据，已从仓库副本移除。原本机设置和受限备份保留，未自动重配账号。
- Quickshell 来源由其本机 About/Welcome 页面指向 `https://github.com/end-4/dots-hyprland`。此次保存的是现用文件快照，无法验证对应的上游提交，附带本机已有许可证。
- Quickshell 中 passwd 启动命令、锁屏/网络运行时密码变量、密码显示枚举和翻译词条触发了 chezmoi 的凭据误报；逐项确认后才导入。真实 API Key 另外使用内容扫描检查。与默认值相同的 `apps.changePassword` 从个人 JSON 中省略，仍使用框架默认命令。
- Git、签名配置中的公开 SSH 公钥保留；没有收录私钥、系统钥匙串或 Git 凭据文件。

## 验证与边界

自动检查涵盖 Shell/Lua/Python 语法、JSON/JSONC/TOML、Git 配置解析、Yazi 插件和快捷键、Hyprland 模块、Matugen 模板引用、部署排除规则及路径限制。

临时恢复进行两次，并用 chezmoi verify/status 检查文件内容、权限、符号链接及幂等性；第二次恢复前改写临时生成主题，确认 create-only 文件不会覆盖生成内容。检查器另有 JSONC 解析和路径越界回归测试。

QML 实际加载、字体/壁纸、输入法、休眠、交互快捷键、联网插件恢复和语言服务器需要人工验收；本次不启动桌面，不更改系统配置。系统依赖版本是现状记录，不保证以后软件源仍能提供所有旧版本。

本机专用显示器参数、应用路径、壁纸路径保留。此仓库定位于同一台机器恢复；换机器时需先调整这些设置。Rime 用户词库、学习数据和系统级安装不是此配置快照的一部分。

Python 检查会报告少数旧脚本正则字符串中的无效转义弃用警告；当前语法检查可通过，未来 Python 升级前应修正。本次不为消除警告改写上游快照。

## 本轮最终结果

- 1,180 个受管文件通过验证；两次临时恢复和生成主题保留测试通过，6 项检查器回归测试通过。
- Zsh 重装入口、缺少可选工具时的启动测试通过；独立临时 Tmux 实例成功加载配置，确认 Ctrl+A 前缀和 CSI-u 设置；tmux-tilit 补丁可应用到记录的提交。
- `git diff --check` 通过。具体计数和 21 项待应用差异见 [verification.json](verification.json)。
- 对比 1,179 个采集文件：两项 Fcitx 文件在初始基线与采集之间发生内容变化，采集副本与最终本机文件一致；其余采集文件与基线一致。未向本机执行 apply，未回写这两项文件。
- 所有变更留在工作区，未暂存、提交或推送。
