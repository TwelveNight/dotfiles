# win：FreeRDP 快捷键切换

`win` 在 Niri + SDL3 Wayland 下加载本目录的独立控制层。系统 FreeRDP、SDL 和 Niri 包不改动，没有新增服务、后台线程或全局 LD_PRELOAD。

## 使用

关闭原来的 FreeRDP 窗口，再运行 `win`。关闭客户端不会关闭 Windows 虚拟机。

- 新连接默认保留本机快捷键。
- 聚焦 Windows 窗口后，Super+Esc 切换为远程接管；再按一次返回本机。
- 选择在本次客户端进程内保持，鼠标出入、切换焦点不会重置；重新启动客户端回到本机模式。
- 本机模式不阻止普通输入：Windows 窗口有焦点时，打字仍然送给 Windows。
- 切换后通知显示当前模式。Super+Esc 始终由 Niri 处理；compositor 保留的安全组合键不保证转发。
- Super+Q、Alt+Q 已移除不可抑制属性，接管时不会在本机关闭 FreeRDP。其他窗口中的关闭／Folia 隐藏动作不变。
- FreeRDP 自带的 grab 快捷键不再是模式控制器；使用 Super+Esc。其其他原生功能快捷键不变。

已运行的旧客户端无法事后加载此库；控制器会提示重新运行 win，而不假装切换成功。

## 文件归属

- 启动器：`~/.local/scripts/win`，chezmoi 源为 `dot_local/scripts/executable_win`。
- 控制器和源码：`~/.local/libexec/win-shortcuts/{control.py,grab.c}`。
- 编译缓存：`~/.cache/win-shortcuts/grab-<source-and-SDL-version-hash>.so`，不放入版本库。
- 运行时端点：`$XDG_RUNTIME_DIR/win-shortcuts/<PID>.sock`。目录 0700、socket 0600，两端校验同一用户，控制器核对对端 PID。
- Nyxuri 键位：`personal/75-personal-binds.kdl`，实机为 `~/.config/nyxuri-desktop/niri/75-personal-binds.kdl`。
- Alt+Q：Nyxuri 的 `personal/binds.kdl` / 实机 `personal-binds.kdl`。

控制器使用 Python 标准库；C 库仅用公开 SDL3 ABI 和 Linux Unix socket。首次启动或源码／SDL 版本改变时，用已有 `cc`、`pkg-config`、SDL3 开发文件编译这个小库，不编译 FreeRDP。普通包更新仍正常进行；升级后应重跑下面的检查，不能假定任意未来 SDL ABI 都兼容。

启动器确认新客户端的控制端点能回读 `local 0` 后才报告就绪。加载失败只停止本次新建的客户端，不关虚拟机或其他 RDP 窗口。控制端点丢失时，下一次 SDL 事件维护点会释放抓键。客户端主线程若完全卡死，辅助层也不能执行；不承诺绕过应用卡死。

## 诊断与验证

聚焦 Windows 窗口后运行 `~/.local/libexec/win-shortcuts/control.py status`。输出由模式和 SDL grab 标志组成：`local 0` / `remote 1`；标志不是对 compositor 当前焦点或远端按键处理的独立确认。

显式诊断可加 `--pid <客户端PID>`，`local` 命令可强制释放。请求只发送一次，不自动重试 toggle；若超时，先查询状态，避免手工重复翻转造成误判。

在 chezmoi 源仓库执行：

```sh
python3 -m unittest discover -s scripts -p 'test_win*.py' -q
bash -n dot_local/scripts/executable_win
shellcheck dot_local/scripts/executable_win
```

可选实机验证：`python3 scripts/probe_win_shortcuts_wayland.py`。需要当前 Niri 会话和已有 python-evdev/uinput 权限。它短暂创建独立 SDL 测试窗口和临时输入设备，只向已确认聚焦的测试窗口发送 C、Q、Super+Esc，结束后移除设备并恢复原焦点；不要与用户打字同时运行。wtype 的 Wayland virtual-keyboard 路径不经过 Niri 常规绑定拦截，不能用于验证本机／远程快捷键归属。测试程序必须提交首帧才能映射为 Niri 窗口。

该测试验证真实 SDL/Niri 快捷键路由，不连接 Windows；实际 FreeRDP 的远端接收、修饰键释放和开始菜单行为仍需在重新连接后确认。

## 撤回

先关闭使用辅助层的客户端。仅撤回启动器中本次新增的 `client_env` 准备、端点确认和 `nohup env` 改动，再 apply `~/.local/scripts/win`；不要整文件覆盖其他待提交修复。

将 Nyxuri 源码和实机的 Super+Esc 动作恢复为 `toggle-keyboard-shortcuts-inhibit`，保留 `allow-inhibiting=false`；如需恢复原关闭键策略，再恢复 Super+Q、Alt+Q 的该属性。运行 `niri validate -c ~/.config/nyxuri-desktop/niri/config.kdl`，确认热重载。

恢复启动器与键位后，本目录和编译缓存才可移除；没有 systemd 单元、系统包或全局环境需要还原。已运行客户端必须退出后，preload 才真正卸载。
