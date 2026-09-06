# Quickshell 个人维护说明

根据 2026-09-06 的用户决定，Quickshell/illogical-impulse 以本机现用配置为起点独立维护。上游更新频率不再作为本地维护的前提；保留原始来源及已有许可证，后续需要的上游修复单独审查、手工合并。

## 已纳入的范围

| 本机路径 | 内容 | 管理方式 |
| --- | --- | --- |
| `~/.config/quickshell/ii/` | QML、JavaScript、服务、脚本、界面模块、资源、翻译 | 完整现用配置直接存入源仓库，目前 930 个受管普通文件，另含链接和目录 |
| `~/.config/illogical-impulse/config.json` | 个人界面和应用偏好 | 作为个人配置维护，凭据留在本机钥匙串 |
| `~/.config/matugen/` | 主题生成配置及模板 | 维护生成输入，不同步运行时生成结果 |
| `~/.config/hypr/` | 桌面与 shell 的集成 | 同仓库维护；生成配色及 shell overrides 使用仅缺失时创建的初始文件 |

`~/.local/state/quickshell/`、缓存、安装标记、私人壁纸和系统钥匙串不纳入普通配置管理。主题偏好修改通过设置或 Matugen 模板完成，避免把生成文件当作手工源文件修改。

## 后续修改流程

1. 在源仓库修改相关文件。服务逻辑主要在 `services/`，界面代码在 `modules/`，共享组件和默认设置在 `modules/common/`；个人选项在 `illogical-impulse/config.json`。
2. 使用 `python scripts/check.py --restore` 检查基础语法、引用和恢复行为。该检查不代替 QML 引擎加载与桌面实际交互验证。
3. 列出本次准确的目标文件、行为变化和恢复方式，取得用户明确确认后才能写入本机。
4. 备份本次涉及的文件，定向应用。QML 文件变化可能触发 Quickshell 自动重载，应在确认时说明；不要顺带重启整个桌面或应用其他待修补配置。
5. 验证本次功能后再提出下一批修改；提交和推送也不自动执行。

本仓库没有针对 Quickshell 的 chezmoi external 下载定义，也不设置自动拉取上游的任务。独立维护不改变应用前逐次确认的约定。

## 本次核对结果

Quickshell 代码和 Matugen 模板与本机一致，无需重复部署。个人 JSON 设置仍有一项未应用差异：仓库省略了与框架默认命令相同的 `apps.changePassword` 字段；本机保留该字段，本次未修改它。其余个人选项在结构化比对中一致。
