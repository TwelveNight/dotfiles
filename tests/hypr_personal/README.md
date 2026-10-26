# Shared Hyprland regressions

Run only on the approved isolated remote host, as a nonroot user. No installation,
compositor, Shell, build, live IPC or display/DDC command is used. Requires Python,
`dbus-run-session` and the existing Debian `liblua5.4.so.0` shared library (the
ctypes runner does not install Lua).

From a transferred chezmoi source snapshot:

```sh
python3 tests/hypr_personal/run.py --work-root /absolute/private/new-case-directory
```

The work root must not exist. The runner copies only Lua source, strips chezmoi
`exact_`/`literal_` attributes into a fixture tree, and creates private HOME, all
XDG paths, TMPDIR, runtime and D-Bus per case with memory GSettings. Logs and
`results.json` remain in the work root. Run no tests against installed targets.

`fixtures/load_ii.lua` is the recording harness retained from the independent
shared-Hyprland review (`SekaiPop/personal/check_full_custom_profiles.lua`), with
its generic assertions/output replaced by returned recording state. It executes
the actual II default/custom load order and models cross-submap `hl.unbind`.
`fixtures/run_lua.py` retains that review's liblua runner and denies OS commands.

Coverage:
- clean entry/escape twice on the unchanged Super+Shift+Alt+P chord;
- Settings disabled, enabled-empty, custom native/shell bindings and absent
  snapshot, checked immediately at config load and after registry reload;
- closed-lid disable -> external DPMS-off restore (even when the disabled panel
  is absent from the monitor list), saved geometry, no repeated restore,
  multiple externals, external disconnect, lid reopening and streaming startup.

Limits: the Hyprland API boundary is recorded, not a real compositor. These
checks do not prove physical keyboard/touchpad events, QML client timing,
real output hotplug/DPMS, DDC, login or streaming acceptance.
