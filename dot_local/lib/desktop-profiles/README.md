# 三套桌面的配置入口

配置实体位于 `~/.config/desktop-profiles/`：

| 桌面 | 配置实体 | 标准入口 |
| --- | --- | --- |
| Hyprland + II | `hyprland-ii/hypr/` | `~/.config/hypr` |
| iNiR | `inir/niri/` | `~/.config/niri` |
| Nyxuri + Noctalia | `nyxuri/{niri,noctalia,kitty-nyxuri}/` | `~/.config/{niri,noctalia,kitty-nyxuri}` |

登录界面的会话条目调用 `desktop-profile run 桌面名`。它在 compositor 启动前
选择链接，再调用原有的 `niri-session`、Nyxuri session.py 或 start-hyprland。
systemd、D-Bus、skwd、输入法和托盘的现有会话交接继续由原有入口完成。
UWSM 登录项直接传入 start-hyprland，避免递归进入修改后的 hyprland.desktop。

只切换当前 compositor 的配置链接。离开 Niri 登录 Hyprland 后，Niri 链接仍指向
上次选择的 Niri 配置；`status` 中的 selected 表示配置选择，不代表桌面正在运行。
同一用户仍按注销后重新登录的方式切换，不同时启动两个图形会话。

Nyxuri 不再把上游的标准配置路径批量改写成 `nyxuri-desktop`。
`NOCTALIA_CONFIG_HOME=~/.config`，由 Noctalia 自己追加 `noctalia/`。
已使用的 `~/.local/state/nyxuri-desktop/noctalia` GUI 状态与缓存保留，
仅更正 GUI 状态中的旧本地插件来源路径，并纳入迁移回退记录。
Nyxuri 内部的效果链接使用相对路径，护眼脚本更新链接时也保持该归属。
源码和安装后的配置实体仍物理分离，软链接只连接标准入口与已安装的配置。

## 查看和编辑

```sh
desktop-profile status
desktop-profile path nyxuri
desktop-profile path inir niri
```

编辑非当前桌面的配置时，用 `path` 返回的实体目录，不要通过当前活动链接编辑。
Quickshell 的 `ii`、`inir` 安装目录及各自设置目录不需要切换。

## 维护

在当前选中的桌面中沿用各自的安装器、`inir update --local` 等命令。
个人安装器先检查标准链接归属；错误归属会在写文件之前停止。

需要从另一个桌面维护时，可由管理器临时选择相应链接，命令退出后恢复原链接：

```sh
desktop-profile maintain inir -- /home/night/Template/github/niri-dots/iNiR/setup update --local
desktop-profile maintain nyxuri -- /home/night/Template/github/niri-dots/Nyxuri-personal/install.sh install --plan
```

如果另一个 Niri 桌面仍在运行，不能临时切换它正在使用的 Niri 配置；请注销后
在 TTY 执行维护。管理器不停止桌面、不注销用户，也不热切换 compositor 配置。
会话锁防止同时登录，转换锁防止链接切换与维护并发；启动失败恢复之前的链接。

Nyxuri 的个人源码固定在 `Nyxuri-personal` 工作树的 `night/personal-overlay`。
`Nyxuri` 原工作树保留在 main，切换它的分支不会改变个人维护入口。
个人分支已适配上游 units/ 架构，继续使用现有 Noctalia 与个人模板。

统一入口：

```sh
desktop-update sync all       # fetch + merge + 验证，不更新 live
desktop-update deploy all     # 再验证、备份、部署
# 或合并运行：desktop-update update all
```

单套用 inir / hyprland-ii / nyxuri 替换 all。普通 inir update、
ii-p3drovfx update、nyxuri update 也进入此流程。另一个 Niri profile
正在运行时，请注销后从 TTY 维护。备份位于
~/.local/state/desktop-profiles/updates/。只同步本次安装器修改的已管理
文件回 chezmoi；源文件已有独立编辑时停止同步，先审查。
详细命令和合并冲突处理见 iNiR 的 scripts/personal/DESKTOP-UPDATES.md。

## chezmoi

chezmoi 管理 Hyprland 和 iNiR 的配置实体以及本管理器，不管理活动软链接。
因此 `chezmoi apply` 不会把正在使用的 Nyxuri 链接重置为 iNiR。
Nyxuri 的生成配置仍由个人安装器部署，`__custom__` 与 manifest preserve 沿用原规则。

## 回退

迁移前的 Noctalia 配置、旧 Kitty 配置和被修改的用户服务保存在
`~/.local/state/desktop-profiles/migration-时间/`，其中 README 给出恢复命令。
恢复配置应在 TTY 中执行；GDM 原会话文件另存于 `/var/lib/desktop-profiles/`。
迁移和会话入口安装都在失败时恢复已修改的项目。

登录项属于系统安装目录。`95-desktop-profiles.hook` 在 niri/Hyprland 包升级后
恢复三个包内登录项的 Exec，保留新包的其他元数据。Nyxuri 登录项由个人安装器维护。
Root helper 固定四个登录项的范围，不读取或执行用户提供的维护命令。
