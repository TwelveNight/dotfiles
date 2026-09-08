-- Edit shell config
hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/quickshell/ii/config.json"),
    {description = "Edit shell config"})
-- Edit keybinds file
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
    {description = "Edit user keybinds"})

-- System keybind overrides
-- Free J/K for window movement (move bar/osk to SUPER+SHIFT+ALT)
hl.unbind("SUPER + J", hl.dsp.global("quickshell:barToggle"))
hl.bind("SUPER + SHIFT + ALT + J", hl.dsp.global("quickshell:barToggle"), {description = "Shell: Toggle bar"})
hl.unbind("SUPER + K", hl.dsp.global("quickshell:oskToggle"))
hl.bind("SUPER + SHIFT + ALT + K", hl.dsp.global("quickshell:oskToggle"), {description = "Shell: Toggle on-screen keyboard"})
-- Free L/SHIFT+L for window movement/resize (move lock/sleep to BackSpace)
hl.unbind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + BackSpace", hl.dsp.exec_cmd("loginctl lock-session"), {description = "Session: Lock"})
hl.unbind("SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"))
hl.bind("SUPER + SHIFT + BackSpace", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"),
    {locked = true, description = "Session: Sleep"})
-- Free W for float toggle (move browser to F, free F from fullscreen → SHIFT+F)
hl.unbind("SUPER + F", hl.dsp.window.fullscreen({mode = "fullscreen", action = "toggle"}))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({mode = "fullscreen", action = "toggle"}),
    {description = "Window: Fullscreen"})
hl.unbind("SUPER + W", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + F", hl.dsp.exec_cmd(browser), {description = "App: Browser"})
-- Free D, repurpose O for maximize (O was sidebarLeftToggle, A already covers that)
hl.unbind("SUPER + O", hl.dsp.global("quickshell:sidebarLeftToggle"))
hl.unbind("SUPER + D", hl.dsp.window.fullscreen({mode = "maximized", action = "toggle"}))
hl.bind("SUPER + O", hl.dsp.window.fullscreen({mode = "maximized", action = "toggle"}),
    {description = "Window: Maximize"})
-- B → right sidebar (A already covers left sidebar)
hl.unbind("SUPER + B", hl.dsp.global("quickshell:sidebarLeftToggle"))
hl.bind("SUPER + B", hl.dsp.global("quickshell:sidebarRightToggle"))
-- Extra overview binding
-- SUPER+Space: same as original bare Win key (searchToggleRelease: press arms, release toggles)
hl.bind("SUPER + Space", hl.dsp.global("quickshell:searchToggleRelease"))
hl.bind("SUPER + Space", hl.dsp.global("quickshell:searchToggleRelease"), {release = true})
hl.bind("SUPER + Space", hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || pkill fuzzel || fuzzel"))
-- Win key: use the upstream release action so a bare Super opens the active
-- panel family's launcher (Waffle Start menu or the ii overview).
hl.unbind("SUPER + SUPER_L", hl.dsp.global("quickshell:searchToggleRelease"))
hl.unbind("SUPER + SUPER_R", hl.dsp.global("quickshell:searchToggleRelease"))
hl.bind("SUPER + SUPER_L", hl.dsp.global("quickshell:searchToggleRelease"), {description = "Shell: Toggle launcher"})
hl.bind("SUPER + SUPER_R", hl.dsp.global("quickshell:searchToggleRelease"))
-- Free N for workspace navigation (unbind sidebarRightToggle)
hl.unbind("SUPER + N", hl.dsp.global("quickshell:sidebarRightToggle"))
-- Free P for workspace navigation (move pin to SUPER+ALT+P)
hl.unbind("SUPER + P", hl.dsp.window.pin())
hl.bind("SUPER + ALT + P", hl.dsp.window.pin(), {description = "Window: Pin"})
-- Free SUPER+ALT+F for fcitx5 (unbind fullscreen spoof)
hl.unbind("SUPER + ALT + F", hl.dsp.window.fullscreen_state({internal = 0, client = 3, action = "toggle"}))

--##! User

-- Media and settings keybinds
-- Keep the original SUPER+I binding and add SUPER+ALT+I for GNOME Settings.
hl.bind(
	"SUPER + ALT + I",
	hl.dsp.exec_cmd("env XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_DESKTOP=gnome gnome-control-center"),
	{description = "App: GNOME Settings"}
)

-- Restore media controls on the requested shortcuts.
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd("playerctl play-pause"),
    {locked = true, description = "Media: Play/pause media"})
hl.bind("CTRL + ALT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"),
    {locked = true, description = "Media: Toggle mute"})
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("playerctl next"),
    {locked = true, description = "Media: Next track"})
hl.bind("CTRL + ALT + H", hl.dsp.exec_cmd("playerctl previous"),
    {locked = true, description = "Media: Previous track"})

-- Screenshot
hl.bind("CTRL + ALT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh s"))
hl.bind("CTRL + ALT + A", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh s"))
hl.bind("CTRL + code:10", hl.dsp.global("quickshell:regionScreenshot"), {description = "Screen snip (Ctrl+1)"})
hl.bind("CTRL + code:10", hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"))
hl.bind("CTRL + ALT + mouse:272", hl.dsp.global("quickshell:regionScreenshot"),
    {description = "Screen snip to clipboard"})
hl.bind("CTRL + ALT + mouse:272",
    hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"))
hl.bind("CTRL + ALT + mouse:273", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh s"),
    {description = "Screen snip and edit"})

-- Window focus (vim-style)
hl.bind("ALT + H", hl.dsp.focus({direction = "l"}))
hl.bind("ALT + L", hl.dsp.focus({direction = "r"}))
hl.bind("ALT + K", hl.dsp.focus({direction = "u"}))
hl.bind("ALT + J", hl.dsp.focus({direction = "d"}))

-- Move windows (vim-style)
hl.bind("SUPER + H", hl.dsp.window.move({direction = "l"}))
hl.bind("SUPER + L", hl.dsp.window.move({direction = "r"}))
hl.bind("SUPER + K", hl.dsp.window.move({direction = "u"}))
hl.bind("SUPER + J", hl.dsp.window.move({direction = "d"}))

-- Resize windows (vim-style)
hl.bind("SUPER + SHIFT + L", hl.dsp.window.resize({x = 30,   y = 0,   relative = true}), {repeating = true})
hl.bind("SUPER + SHIFT + H", hl.dsp.window.resize({x = -30,  y = 0,   relative = true}), {repeating = true})
hl.bind("SUPER + SHIFT + K", hl.dsp.window.resize({x = 0,    y = -30, relative = true}), {repeating = true})
hl.bind("SUPER + SHIFT + J", hl.dsp.window.resize({x = 0,    y = 30,  relative = true}), {repeating = true})
hl.bind("SUPER + code:21",   hl.dsp.window.resize({x = 30,   y = 0,   relative = true}), {repeating = true})
hl.bind("SUPER + code:20",   hl.dsp.window.resize({x = -30,  y = 0,   relative = true}), {repeating = true})

-- Workspace navigation
hl.unbind("ALT + Tab", hl.dsp.global("quickshell:waffleAltTab"))
hl.unbind("ALT + Tab", hl.dsp.window.cycle_next())
hl.unbind("ALT + Tab", hl.dsp.window.bring_to_top())
-- Match ii's upstream Alt-Tab pattern: transparent root bindings use the
-- physical Tab key and talk to the switcher over IPC. This keeps Alt's first
-- release visible to Hyprland, instead of relying on a submap entered after
-- Alt was already held.
hl.bind("ALT + code:23", hl.dsp.exec_cmd("qs -c ii ipc call altTab next"), {
    transparent = true,
    repeating = true,
    description = "Window: Next with preview",
})
hl.bind("ALT + SHIFT + code:23", hl.dsp.exec_cmd("qs -c ii ipc call altTab previous"), {
    transparent = true,
    repeating = true,
    description = "Window: Previous with preview",
})
hl.bind("ALT + Escape", hl.dsp.exec_cmd("qs -c ii ipc call altTab cancel"), {
    transparent = true,
    description = "Window: Cancel preview",
})
for _, key in ipairs({ "ALT_L", "ALT_R" }) do
    hl.bind(key, hl.dsp.exec_cmd("qs -c ii ipc call altTab accept"), {
        ignore_mods = true,
        transparent = true,
        release = true,
        description = "Window: Confirm preview",
    })
end
hl.bind("SUPER + N",                hl.dsp.focus({workspace = "e+1"}))
hl.bind("SUPER + P",                hl.dsp.focus({workspace = "e-1"}))
hl.bind("SUPER + CTRL + SHIFT + N", hl.dsp.window.move({workspace = "empty", follow = false}))
hl.bind("SUPER + CTRL + SHIFT + O", hl.dsp.focus({workspace = "empty"}))
hl.bind("SUPER + CTRL + SHIFT + H", hl.dsp.window.move({workspace = "-1", follow = false}))
hl.bind("SUPER + CTRL + SHIFT + L", hl.dsp.window.move({workspace = "+1", follow = false}))
hl.bind("SUPER + ALT + Z",          hl.dsp.focus({workspace = "r-10"}))
hl.bind("SUPER + ALT + X",          hl.dsp.focus({workspace = "r+10"}))

-- Move to adjacent workspaces and follow, matching SUPER+ALT+scroll
hl.bind("SUPER + ALT + H",     hl.dsp.window.move({workspace = "-1"}), {description = "Window: Move to previous workspace"})
hl.bind("SUPER + ALT + L",     hl.dsp.window.move({workspace = "+1"}), {description = "Window: Move to next workspace"})
hl.bind("SUPER + ALT + Left",  hl.dsp.window.move({workspace = "-1"}), {description = "Window: Move to previous workspace"})
hl.bind("SUPER + ALT + Right", hl.dsp.window.move({workspace = "+1"}), {description = "Window: Move to next workspace"})
hl.bind("SUPER + ALT + Up",    hl.dsp.window.move({workspace = "-1"}), {description = "Window: Move to previous workspace"})
hl.bind("SUPER + ALT + Down",  hl.dsp.window.move({workspace = "+1"}), {description = "Window: Move to next workspace"})

-- Float window: toggle + center + resize to 50%x60%
hl.bind("SUPER + W", hl.dsp.window.float({action = "toggle"}))
hl.bind("SUPER + W", hl.dsp.window.center())
hl.bind("SUPER + W", hl.dsp.exec_cmd("hyprctl dispatch resizeactive exact 50% 60%"))

-- Mouse actions
hl.unbind("SUPER + mouse:274", hl.dsp.window.drag())
hl.bind("SUPER + mouse:274",          hl.dsp.window.fullscreen({mode = "maximized", action = "toggle"}))
hl.bind("SUPER + SHIFT + mouse:274",  hl.dsp.window.fullscreen_state({internal = 0, client = 3, action = "toggle"}))
hl.bind("SUPER + ALT + mouse:274",    hl.dsp.window.fullscreen({mode = "fullscreen", action = "toggle"}))
hl.bind("SUPER + ALT + O",            hl.dsp.window.fullscreen({mode = "fullscreen", action = "toggle"}))
hl.unbind("SUPER + SHIFT + mouse_up",   hl.dsp.window.move({workspace = "r+1"}))
hl.unbind("SUPER + SHIFT + mouse_down", hl.dsp.window.move({workspace = "r-1"}))
hl.bind("SUPER + SHIFT + mouse_up",     hl.dsp.window.move({workspace = "r-1"}))
hl.bind("SUPER + SHIFT + mouse_down",   hl.dsp.window.move({workspace = "r+1"}))
hl.unbind("SUPER + ALT + mouse_up",   hl.dsp.window.move({workspace = "r+1"}))
hl.unbind("SUPER + ALT + mouse_down", hl.dsp.window.move({workspace = "r-1"}))
hl.bind("SUPER + ALT + mouse_up",     hl.dsp.window.move({workspace = "-1"}))
hl.bind("SUPER + ALT + mouse_down",   hl.dsp.window.move({workspace = "+1"}))
hl.bind("CTRL + SUPER + mouse:274",   hl.dsp.exec_cmd("~/.config/hypr/scripts/dontkillsteam.sh"))
hl.bind("CTRL + SUPER + mouse:273",   hl.dsp.window.float({action = "toggle"}))
hl.bind("ALT + SHIFT + mouse:272",    hl.dsp.window.move({workspace = "empty"}))
hl.bind("ALT + SHIFT + mouse:273",    hl.dsp.focus({workspace = "empty"}))
hl.bind("CTRL + SHIFT + mouse:272",   hl.dsp.window.move({workspace = "e-1", follow = false}))
hl.bind("CTRL + SHIFT + mouse:273",   hl.dsp.window.move({workspace = "e+1", follow = false}))
hl.bind("SUPER + CTRL + mouse:272",   hl.dsp.window.resize(), {mouse = true})

-- Scripts
hl.bind("CTRL + SHIFT + A",          hl.dsp.exec_cmd("~/.config/hypr/scripts/tmux.sh"),                   {description = "Terminal (tmux)"})
hl.bind("CTRL + SHIFT + Z",          hl.dsp.exec_cmd("~/.config/hypr/scripts/1password.sh"),              {description = "Toggle 1Password"})
hl.bind("CTRL + SHIFT + SPACE",      hl.dsp.exec_cmd("~/.config/hypr/scripts/1password-quick-access.sh"), {description = "1Password quick access"})
hl.bind("SUPER + ALT + F",           hl.dsp.exec_cmd("fcitx5 --replace -d"),                              {description = "Restart fcitx5"})
hl.bind("CTRL + SUPER + F",          hl.dsp.exec_cmd("fcitx5 --replace -d"))

-- Rofi
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("pkill rofi || rofi -show filebrowser"), {description = "File browser (rofi)"})

-- XWayland file manager for dragging files to QQ/WeChat
hl.bind("SUPER + ALT + E", hl.dsp.exec_cmd("env QT_QPA_PLATFORM=xcb pcmanfm-qt --profile xwayland --new-window"),
    {description = "App: XWayland file manager"})

-- Volume (Ctrl+Alt+J/K/arrows)
hl.bind("CTRL + ALT + J",    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"), {repeating = true})
hl.bind("CTRL + ALT + K",    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+"), {repeating = true})
hl.bind("CTRL + ALT + Down", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"), {repeating = true})
hl.bind("CTRL + ALT + Up",   hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+"), {repeating = true})

-- ALT+Space: same as SUPER+Tab (overview toggle on press), unbind vicinae
hl.unbind("ALT + Space", hl.dsp.exec_cmd("vicinae"))
hl.bind("ALT + Space", hl.dsp.global("quickshell:overviewWorkspacesToggle"))

-- Vicinae clipboard
hl.bind("ALT + Space", hl.dsp.exec_cmd("vicinae"), {description = "Vicinae clipboard"})

-- Clean submap (passthrough all keys, exit with Super+Shift+Alt+P)
hl.define_submap("clean", function()
    hl.bind("SUPER + SHIFT + ALT + P", function()
        hl.dispatch(hl.dsp.exec_cmd("notify-send 'Exited clean submap' 'Keybinds re-enabled' -a 'Hyprland'"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, {submap_universal = true})
end)
hl.bind("SUPER + SHIFT + ALT + P", function()
    hl.dispatch(hl.dsp.exec_cmd("notify-send 'Entered clean submap' 'Keybinds disabled. Hit Super+Shift+Alt+P to escape' -a 'Hyprland'"))
    hl.dispatch(hl.dsp.submap("clean"))
end)
