# Desktop configuration maintenance

As of 2026-10-19, Hyprland + II, iNiR and Nyxuri + Noctalia 5 have independent
installed configuration payloads under `~/.config/desktop-profiles/`.
GDM session entries call `desktop-profile` before starting the compositor.
The session manager owns canonical symlinks; chezmoi owns payload files and the manager.
Applying chezmoi cannot select iNiR over an active Nyxuri session.

| Configuration | Source-managed payload |
| --- | --- |
| Hyprland + II | `~/.config/desktop-profiles/hyprland-ii/hypr` |
| iNiR Niri | `~/.config/desktop-profiles/inir/niri` |
| Nyxuri | Personal installer owns `~/.config/desktop-profiles/nyxuri` |

Quickshell `ii` and `inir` runtime directories remain plain installed copies
owned by their personal repositories. They are not vendored into chezmoi.
Shell settings, state, caches and application preferences retain their existing owners.

Use `desktop-profile status` to inspect selection and `desktop-profile path NAME`
to locate a payload. The manager's complete workflow and rollback notes are in
`~/.local/lib/desktop-profiles/README.md` (source: `dot_local/lib/desktop-profiles/README.md`).

Edit inactive configurations through their payload paths. Sync accepted live changes with
`chezmoi re-add` on the payload path. Do not add the canonical niri/hypr symlinks to chezmoi.

## Upstream and live updates

Use `desktop-update sync all` to fetch, merge and test each registered personal
checkout, then `desktop-update deploy all` to back up and deploy the reviewed
sources. `desktop-update update all` combines both. The upstream branches are
iNiR origin/prerelease, II origin/dev and Nyxuri origin/main.

The installer mirrors only managed files it changed back to chezmoi, after
checking that the source has no independent edits. It never re-adds the entire
home or the runtime shell trees. Use a TTY after logging out when maintenance
would select a different Niri profile. Conflicts stop before later deployment;
resolve and commit them, then run verify/deploy. No automatic push occurs.
