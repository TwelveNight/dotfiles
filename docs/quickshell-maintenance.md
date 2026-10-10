# Quickshell shell maintenance notes

As of 2026-10-10, the desktop runs the **iNiR** shell on Niri. The older **ii/illogical-impulse** checkout remains installed as a secondary shell from the Hyprland era.

Neither shell body is managed by chezmoi. Each shell is a full checkout of its own Git repository and is deployed by that repository's own installer; chezmoi only versions the shell *settings* (see the README's "Shell checkouts" section).

## Repositories and branches

| Shell | Checkout | Upstream | Personal remote/branch |
| --- | --- | --- | --- |
| iNiR (active) | `~/.config/quickshell/inir` | [snowarch/iNiR](https://github.com/snowarch/iNiR) (`origin`) | [TwelveNight/iNiR](https://github.com/TwelveNight/iNiR) (`personal`), `night/personal-overlay` |
| ii (secondary) | `~/.config/quickshell/ii` | [P3DROVFX/ii-p3drovfx](https://github.com/P3DROVFX/ii-p3drovfx) (`origin`) | [TwelveNight/ii-p3drovfx](https://github.com/TwelveNight/ii-p3drovfx) (`personal`), `night/personal-overlay` |

The development checkouts live outside `~/.config` (`~/Template/github/niri-dots/iNiR` and `~/Template/github/hyprland-dots/ii-p3drovfx`); the deployed copies under `~/.config/quickshell/` are plain directory copies without their own `.git`. Personal changes are committed on `night/personal-overlay` in the development checkout, deployed with the shell's own tooling, and pushed to the `personal` remote for backup.

## Managed scope

| Local path | Contents | Management |
| --- | --- | --- |
| `~/.config/quickshell/inir/` | Active iNiR shell code and assets | Unmanaged by chezmoi; owned by the iNiR repository |
| `~/.config/quickshell/ii/` | Secondary ii shell code and assets | Unmanaged by chezmoi; owned by the ii-p3drovfx repository |
| `~/.config/inir/` | iNiR settings: `config.json`, `migrations.json`, `version*`, `matugen/` templates | Managed by chezmoi; runtime state (`backups/`, `actions/`, `installed_*`, locks) excluded |
| `~/.config/niri/` | Niri compositor entry point and `config.d/` includes | Managed by chezmoi |
| `~/.config/illogical-impulse/` | Leftover ii-era settings | Unmanaged; kept locally for reference |
| `~/.config/hypr/` | Secondary compositor configuration | Managed by chezmoi |

`~/.local/state/quickshell/`, `~/.local/state/inir/`, caches, installation markers, private wallpapers and system keyrings are outside ordinary configuration management. Change theme preferences through Settings or Matugen inputs instead of treating generated files as hand-edited sources.

## Change workflow

1. Edit the relevant files in the shell's development checkout, not in the deployed `~/.config/quickshell/` copy. Personal settings changes belong in `~/.config/inir/config.json` (via the Settings UI) and sync back with `chezmoi re-add`.
2. Follow the shell repository's own verification (`make build` for the iNiR Go tooling, `niri validate` for compositor configuration).
3. Deploy with the shell's own tooling: `inir update --local` for iNiR; do not copy files between the checkout and the live directory by hand.
4. Verify the feature in the running desktop before starting another batch. Commits, pushes to `personal`, and chezmoi syncs of the settings files are separate operations.

There are no chezmoi externals or automatic upstream-pull jobs for either shell. An earlier revision of this repository vendored the full ii snapshot (~4800 files) and briefly declared both shells as chezmoi `git-repo` externals; both approaches were removed because they duplicate the shells' own repository ownership.

## Current audit

The deployed iNiR shell matches the tip of `night/personal-overlay` in its development checkout (deployed via `inir update --local`). The iNiR settings and Niri configuration in chezmoi match the live files. The ii checkout at `~/.config/quickshell/ii` matches commit `0e061644` of its personal branch.
