-- Bare Super opens search only while the Waffle family owns its dedicated
-- global shortcut. Other panel families do not register this action.
hl.unbind("SUPER + SUPER_L", hl.dsp.global("quickshell:searchToggleRelease"))
hl.unbind("SUPER + SUPER_R", hl.dsp.global("quickshell:searchToggleRelease"))
hl.unbind("SUPER + SUPER_L", hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE ping || pkill fuzzel || fuzzel"))
hl.unbind("SUPER + SUPER_R", hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE ping || pkill fuzzel || fuzzel"))
hl.bind("SUPER + SUPER_L", hl.dsp.global("quickshell:waffleSearchToggleRelease"), {description = "Waffle: Toggle search"})
hl.bind("SUPER + SUPER_R", hl.dsp.global("quickshell:waffleSearchToggleRelease"))

require("custom.shared").keybinds()
