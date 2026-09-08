# Quickshell maintenance notes

As of 2026-09-06, Quickshell/illogical-impulse is maintained as an active local snapshot. Upstream update frequency is not a prerequisite for this setup; upstream fixes are reviewed and merged manually when useful.

## Managed scope

| Local path | Contents | Management |
| --- | --- | --- |
| `~/.config/quickshell/ii/` | QML, JavaScript, services, scripts, UI modules, assets and translations | The complete active snapshot is stored in the source repository |
| `~/.config/illogical-impulse/config.json` | Personal UI and application preferences | Managed as personal configuration; credentials stay in the local keyring |
| `~/.config/matugen/` | Theme-generation inputs and templates | Inputs are managed; generated runtime output is not |
| `~/.config/hypr/` | Desktop and shell integration | Managed together with the shell; generated colors and overrides are create-only |

`~/.local/state/quickshell/`, caches, installation markers, private wallpapers and system keyrings are outside ordinary configuration management. Change theme preferences through Settings or Matugen inputs instead of treating generated files as hand-edited sources.

## Change workflow

1. Edit the relevant source files. Service logic lives mainly in `services/`, UI code in `modules/`, shared components and defaults in `modules/common/`, and personal options in `illogical-impulse/config.json`.
2. Run `python scripts/check.py --restore` for syntax, reference and restore checks. This does not replace QML-engine loading or desktop interaction testing.
3. List the exact target files, behavior changes and rollback location before applying a change.
4. Back up the affected files and deploy them selectively. QML changes may trigger a Quickshell reload; do not restart the whole desktop or apply unrelated pending changes.
5. Verify the feature before starting another batch. Commits and pushes are separate operations.

There are no chezmoi externals or automatic upstream-pull jobs for Quickshell. Local maintenance remains intentionally explicit.

## Current audit

The Quickshell code and Matugen templates match the active local setup. The personal JSON omits `apps.changePassword` because it equals the framework default; the local file may retain that explicit default. Other personal options are structurally aligned.
