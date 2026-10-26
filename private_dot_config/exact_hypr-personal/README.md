# 三套 Hyprland 的共享个人配置

唯一维护源：`chezmoi source-path ~/.config/hypr-personal`。
运行时：`~/.config/hypr-personal/`，通过 `chezmoi apply ~/.config/hypr-personal`
部署。修改共享模块后重载 Hyprland；下一次登录其他 Hyprland 桌面也会使用同一份。

SekaiPop、Hyprland + II 和 Vitreus 的个人层只负责加载本包及提供
overview 的 shell 回退。模块不依赖三个源代码仓库，不启动或选择其他桌面。
个人外观、输入、规则、应用偏好、启动应用、手势和键位均由本包提供。
各环境仅保留显示器坐标、shell 生命周期、主题生成文件、布局设置和专属 UI 适配。
仅兼容当前使用的 Hyprland Lua API（含原生 scrolling），不供 Niri/pleamar-wm 使用。

共享行为：盖子/熄屏监视器策略，工作区分组及自动补齐，末尾空工作区，边缘逐窗导航
（含最大化转移），左上角 ScrollOverview，Alt+H/J/K/L 和 Alt+滚轮聚焦，
Alt+M 全屏，Alt+C 居中，Super+R 1/4、1/2、3/4 宽度，Super+[/] 合并/拆列。
Alt+Q 与 Super+Q 使用同一回调；SekaiPop 提供自身的 Folia 托盘关闭回调。
双屏分组外屏 1–10、内屏 11–20；只有内屏时 1–10。

布局仍在各环境设置中选择 Scrolling，本包不会强制改写 `general.layout`。
ScrollOverview 需要当前 Hyprland 对应的已启用 hyprpm 插件；启动时仅在尚未加载时
调用 `hyprpm reload -n`。不可用时热角回退到所在桌面的 overview。

加载器可通过 `HYPR_PERSONAL_DIR` 指向隔离测试副本；正常会话无需设置此变量。
回归测试保留在 SekaiPop 的 `personal/test_hypr_custom.py`，测试共享包及实际接入层。

个人配置放在本包的 `custom/` 下：`custom/hypr_personal.lua` 管理共享键位和入口，
`custom/hypr_personal/*.lua` 管理导航、工作区等行为。三套配置的
`hypr/custom/shared.lua` 只接入这个目录。浏览器通过各自 adapter 的 `browser`
选项提供，默认 Firefox；Win+F 打开浏览器，Ctrl+Shift+Esc 用 Kitty 打开 btop。
Win+H/J/K/L 移动窗口，Alt+H/J/K/L 切焦点并跟随光标，
Win+Shift+H/J/K/L 调整窗口尺寸。


## 完整 custom 归属

| 原 custom 文件或功能 | 共享实现 / 适配边界 |
| --- | --- |
| variables.lua | custom/hypr_personal/variables.lua；Kitty、浏览器、编辑器、btop、10 个一组 |
| env.lua | env.lua；PCI DRM 顺序、NVIDIA、Fcitx、Neovim、Bibata；Vitreus 启动前 GPU wrapper 仍保留 |
| general.lua、input.lua | general.lua；间距、边框、圆角、模糊、触摸板、软件光标、虚拟触屏 |
| gestures.lua | gestures.lua；3 指工作区/暂存区、4 指移动/浮动、5 指搜索/最大化 |
| rules.lua、hermes_pet.lua | rules.lua、hermes_pet.lua；完整应用规则和宠物标题动态处理 |
| hyprglass.lua | hyprglass.lua；仅配置已加载插件，不作用于 shell 图层 |
| keybinds.lua | keybinds.lua；全部工作区、鼠标、媒体、截图、会话、应用、clean 子映射和 Niri 操作 |
| scripts/hide-folia.py、close-or-hide-steam.sh | scripts/；Folia 托盘隐藏、Steam 不退出 |
| scripts/tmux.sh、screenshot-edit.sh | scripts/；tmux、grim/slurp/swappy |
| execs.lua、scripts/autostart.sh | autostart()、scripts/autostart.sh；Fcitx、Clash、1Password，等待本会话托盘 |
| monitor_policy/workspaces/edge_focus/empty_workspace/compact_workspaces | 同名共享模块（empty_workspace → spare_workspace） |
| focus_navigation/window_center/column_layout | 同名共享模块 |
| monitors.lua | 每套保留自己的坐标原点；共享熄屏、合盖、分组策略，不覆盖远程绝对输入坐标 |
| switcher.lua、WindowSwitcher.qml | SekaiPop 自己的 MRU 预览；II 保留上游 WindowSwitcher；Vitreus 保留自己的循环切换 |
| scripts/focus-window-direction.sh | 历史备用，现由共享 focus_navigation.lua 取代，不再绑定 |
| II inir-session.lua | 保留 II/iNiR 服务生命周期；不在另外两个 shell 启动 II 服务 |
| II scripts/__restore_video_wallpaper.sh | 上游生成的空模板，非个人行为，不跨 shell 运行 |

不把不同 shell 的界面文件相互复制。II 没有 SekaiPop 的 focus toggle 接口；
Vitreus 没有对应 focus mode / 屏幕键盘界面，这些组合在相应 shell 解绑，
不绑定不存在的接口、不启动别的 shell。其余操作由 adapter 指向本 shell。
各 shell 生成的主题/颜色和 Settings 最后加载，仍可覆盖个人外观。

## 冲突及改键（Win = Super）

全部个人键位注册前会解绑旧组合（含旧组合上的多重 dispatcher），再注册唯一动作。
同一功能已有另一入口时保留现有入口；没有入口的原功能移到下表。
数字键和 code:10 等物理键、Equal/code:21 等别名按同一个真实按键核对。

| 原组合 / 功能 | 个人用途 | 原功能现在的入口 |
| --- | --- | --- |
| Win+L / 锁屏 | 右移窗口 | Win+Backspace |
| Win+Shift+L / 挂起 | 调整窗口宽度 | Win+Shift+Backspace |
| Win+F / 全屏 | 浏览器 | Alt+M、Win+Shift+F |
| Win+W / 浏览器 | 浮动、居中、50%×60% | Win+F |
| Win+P / 窗口置顶 | 上个工作区 | Ctrl+Win+Alt+P |
| Win+Space / 切换键盘布局（II） | 总览 | Ctrl+Win+Space |
| Win+R / OLED saver（II） | 切换 1/4、2/4、3/4 宽 | Ctrl+Win+Alt+R |
| Win+[/] / 左右聚焦 | 合并/拆开局部列 | Alt+H/L（含熄屏过滤） |
| Win+Equal/Minus / 缩放 | 窗口宽度 | Ctrl+Win+Equal/Minus |
| Win+K / 屏幕键盘 | 上移窗口 | Win+Shift+Alt+K（SekaiPop、II） |
| Win+J / 显隐栏（II） | 下移窗口 | Win+Shift+Alt+J |
| Win+Alt+N / 笔记（II） | 移动窗口到下个工作区 | Win+Shift+Alt+N |
| Win+N / 面板 | 下个工作区 | Win+A/B；II 右侧面板 Win+B |
| Win+O / II 左侧面板 | 最大化 | Win+A |
| Win+D / 最大化、Vitreus Desk | 释放旧最大化键 | 最大化 Win+O；Desk Ctrl+Win+Alt+D、桌面编辑组合 |
| Win+B / Vitreus 壁纸 | Dashboard | Ctrl+Win+W |
| Win+Shift+E / 桌面编辑 | Rofi 文件浏览器 | Ctrl+Win+Shift+Alt+E |
| Win+Shift+F / SekaiPop 专注 | 全屏 | Win+Shift+Alt+F |
| Win+Alt+F / 假全屏 | 重启 Fcitx | Win+Shift+O |
| Alt+Space / Vicinae（II） | 当前 shell 搜索 | Alt+Shift+Space |
| Ctrl+Win+/ / 编辑 II JSON | 当前 shell 设置 | Ctrl+Win+Alt+/ 打开共享个人键位；II JSON 编辑迁到 Ctrl+Win+Alt+I |

Ctrl+Win+P 的 II 面板系列切换保持原键；新置顶键特意不占用它。
Ctrl+1 与 Ctrl+code:10 只保留一个截图动作；Win+Equal 与 Win+code:21 同理。
共享启动项不启动 cc-switch，也不启动其他桌面的 shell/壁纸服务。

II 的 custom/amd-drm-card、nvidia-drm-card 是本机设备软链接，保留原样；
共享 env 按 PCI 解析设备路径，其他 profile 不需要复制这些链接。
custom/scripts/mpvpaper_thumbnails 是壁纸缩略图缓存，不是配置，不跨 shell 部署。
II 的 settingsApp 使用本 shell 的原生设置入口；不传播 qs -c ii 到其他 shell。

当前 Hyprland Lua 的 code:N 字符串会注册成空键（原生 config 校验不报错），
因此个人配置使用 Equal/Minus/1 键名；live 已检查不再留下空键绑定。

Scrolling 下 Win+H/J/K/L 交换左右/上下窗口的既有位置，不改变列成员。
浮动窗口和其他布局仍使用原生方向移动。Win+[/] 继续负责合列/拆列。
