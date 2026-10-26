hl.unbind("CTRL+SUPER+ALT+Slash")
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr-personal/custom/hypr_personal/keybinds.lua"), {description = "Shell (more): Edit user keybinds"} )

hl.unbind("SUPER + Return")
hl.bind("SUPER + Return",hl.dsp.exec_cmd(terminal),{description="Apps: Terminal"})

-- All replacements clear the original chord, including stacked dispatchers.
local function bind(keys, action, description, options)
    hl.unbind(keys)
    options = options or {}
    options.description = description
    hl.bind(keys, action, options)
end
local function command(keys, cmd, description, options)
    bind(keys, hl.dsp.exec_cmd(cmd), description, options)
end
local personal=require("hypr_personal")
local function shell(keys, call, description)
    hl.unbind(keys)
    if personal.options.actions[call] then bind(keys, personal.action(call), "Shell: " .. description) end
end
local scripts = "~/.config/hypr-personal/scripts/"
local function close_window()
    local window = hl.get_active_window()
    if window and window.class == "folia-major" and window.title == "Folia" then
        hl.exec_cmd("python3 " .. scripts .. "hide-folia.py " .. window.address .. " " .. tostring(window.pid))
    else
        hl.dispatch(hl.dsp.window.close())
    end
end
local maximize = hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })
local fullscreen = hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })
local spoof = hl.dsp.window.fullscreen_state({ internal = 0, client = 3, action = "toggle" })
-- Native SekaiPop counterparts of II's panels/search/overview.
shell("SUPER + A", "quickpanel toggle", "Toggle quick panel")
shell("SUPER + B", "quickpanel toggle", "Toggle quick panel")
shell("ALT + Space", "launcherphone toggle", "Toggle app search")
shell("SUPER + Space", "overview toggle", "Toggle overview")
shell("SUPER + SHIFT + ALT + K", "keyboard toggle", "Toggle on-screen keyboard")
shell("SUPER + SHIFT + ALT + F", "focus toggle", "Toggle focus mode")
shell("CTRL + SUPER + SHIFT + ALT + E", "desktopedit toggle", "Edit desktop")
shell("CTRL + SUPER + Slash", "settings toggle", "Toggle settings")
-- Wallpaper stays native: skwd-wall would compete with parallax/video layers.
shell("CTRL + SUPER + W", "wallpaperpicker toggle", "Change wallpaper")
command("SUPER + BackSpace", personal.options.actions.lock, "Session: Lock screen")
command("SUPER + SHIFT + BackSpace", "systemctl suspend || loginctl suspend", "Session: Sleep", { locked = true })
bind("CTRL + ALT + Delete", personal.action("session"), "Session: Open menu")
hl.unbind("SUPER + D") -- Maximize moves to O.
bind("SUPER + SHIFT + F", fullscreen, "Windows: Fullscreen")
bind("SUPER + O", maximize, "Windows: Maximize")
bind("SUPER + SHIFT + O", spoof, "Windows: Fullscreen spoof")
bind("SUPER + ALT + O", fullscreen, "Windows (more): Fullscreen")
command("SUPER + ALT + F", "fcitx5 --replace -d", "Apps: Restart input method")
command("CTRL + SUPER + F", "fcitx5 --replace -d", "Apps (more): Restart input method")
command("SUPER + ALT + I", "env XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_DESKTOP=gnome gnome-control-center", "Apps: GNOME Settings")
command("SUPER + ALT + E", "env QT_QPA_PLATFORM=xcb pcmanfm-qt --profile xwayland --new-window", "Apps: XWayland file manager")
command("SUPER + SHIFT + E", "pkill -x rofi || rofi -show filebrowser", "Apps: File browser")

-- Use key symbols: this Hyprland Lua build silently registers code:N as empty keys.
hl.unbind("SUPER + Equal")
hl.unbind("SUPER + Minus")
-- Vim movement and resizing are provided by custom.shared.

bind("SUPER + Equal", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), "Windows (more): Grow window", { repeating = true })
bind("SUPER + Minus", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), "Windows (more): Shrink window", { repeating = true })
-- Retain zoom on a free chord.
for _, spec in ipairs({{"Equal",0.3},{"Minus",-0.3}}) do
    bind("CTRL + SUPER + " .. spec[1], function()
        hl.config({ cursor = { zoom_factor = math.max(1, math.min(3, hl.get_config("cursor:zoom_factor") + spec[2])) } })
    end, "Screen: Zoom", { repeating = true })
end

-- Workspace groups: 1..10 on external, 11..20 on internal with two outputs.
local function numbered_workspace(number)
    local workspace = hl.get_active_workspace()
    return math.floor((math.max(1, workspace and workspace.id or 1) - 1) / 10) * 10 + number
end
for i = 1, 10 do
    bind("SUPER + " .. (i % 10), function()
        hl.dispatch(hl.dsp.focus({ workspace = numbered_workspace(i) }))
    end, "Workspaces: Focus workspace # (1-10)")
    bind("SUPER + ALT + " .. (i % 10), function()
        hl.dispatch(hl.dsp.window.move({ workspace = numbered_workspace(i), follow = false }))
    end, "Windows: Send to workspace # (1-10)")
end
bind("SUPER + N", hl.dsp.focus({ workspace = "e+1" }), "Workspaces: Next workspace")
bind("SUPER + P", hl.dsp.focus({ workspace = "e-1" }), "Workspaces: Previous workspace")
bind("SUPER + CTRL + SHIFT + N", hl.dsp.window.move({ workspace = "empty", follow = true }), "Windows: Move to new workspace and follow")
bind("SUPER + CTRL + SHIFT + O", hl.dsp.focus({ workspace = "empty" }), "Workspaces: New empty workspace")
bind("SUPER + CTRL + SHIFT + H", hl.dsp.window.move({ workspace = "-1", follow = false }), "Windows: Send to previous workspace")
bind("SUPER + CTRL + SHIFT + L", hl.dsp.window.move({ workspace = "+1", follow = false }), "Windows: Send to next workspace")
bind("SUPER + ALT + Z", hl.dsp.focus({ workspace = "r-10" }), "Workspaces: Previous workspace group")
bind("SUPER + ALT + X", hl.dsp.focus({ workspace = "r+10" }), "Workspaces: Next workspace group")
for _, key in ipairs({"P","H","Left","Up","mouse_up"}) do
    bind("SUPER + ALT + " .. key, hl.dsp.window.move({ workspace = "-1", follow = true }), "Windows: Move to previous workspace and follow")
end
for _, key in ipairs({"N","L","Right","Down","mouse_down"}) do
    bind("SUPER + ALT + " .. key, hl.dsp.window.move({ workspace = "+1", follow = true }), "Windows: Move to next workspace and follow")
end
bind("SUPER + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "r-1", follow = true }), "Windows: Move to previous workspace and follow")
bind("SUPER + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "r+1", follow = true }), "Windows: Move to next workspace and follow")

bind("SUPER + W", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.center())
    hl.exec_cmd("hyprctl dispatch resizeactive exact 50% 60%")
end, "Windows: Toggle floating and center")
bind("SUPER + mouse:274", maximize, "Windows: Maximize")
bind("SUPER + SHIFT + mouse:274", spoof, "Windows: Fullscreen spoof")
bind("SUPER + ALT + mouse:274", fullscreen, "Windows: Fullscreen")
bind("CTRL + SUPER + mouse:273", hl.dsp.window.float({ action = "toggle" }), "Windows: Toggle floating")
bind("SUPER + CTRL + mouse:272", hl.dsp.window.resize(), "Windows: Resize window", { mouse = true })
bind("ALT + SHIFT + mouse:272", hl.dsp.window.move({ workspace = "empty", follow = true }), "Windows: Move to new workspace and follow")
bind("ALT + SHIFT + mouse:273", hl.dsp.focus({ workspace = "empty" }), "Workspaces: New empty workspace")
bind("CTRL + SHIFT + mouse:272", hl.dsp.window.move({ workspace = "e-1", follow = false }), "Windows: Send to previous workspace")
bind("CTRL + SHIFT + mouse:273", hl.dsp.window.move({ workspace = "e+1", follow = false }), "Windows: Send to next workspace")
command("CTRL + SUPER + mouse:274", "sh " .. scripts .. "close-or-hide-steam.sh", "Windows: Close window (hide Steam)")

-- Personal screenshots: native region UI for copy, grim/slurp/swappy for edit.
local screenshot = personal.options.actions.screenshot
command("CTRL + 1", screenshot, "Utilities: Screen snip")
command("CTRL + ALT + mouse:272", screenshot, "Utilities: Screen snip")
for _, key in ipairs({"CTRL + ALT + S","CTRL + ALT + A","CTRL + ALT + mouse:273"}) do
    command(key, "sh " .. scripts .. "screenshot-edit.sh", "Utilities: Screen snip and edit")
end
command("CTRL + SHIFT + A", "sh " .. scripts .. "tmux.sh", "Apps: Terminal (tmux)")
command("CTRL + SHIFT + Z", "1password --toggle", "Apps: Toggle 1Password")
command("CTRL + SHIFT + Space", "1password --quick-access", "Apps: 1Password quick access")

for _, spec in ipairs({{"P","playerctl play-pause"},{"M","wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"},
    {"H","playerctl previous"},{"Left","playerctl previous"},{"L","playerctl next"},{"Right","playerctl next"},
    {"mouse:275","playerctl previous"},{"mouse:277","playerctl previous"},{"mouse:276","playerctl next"},{"mouse:278","playerctl next"}}) do
    command("CTRL + ALT + " .. spec[1], spec[2], "Media: " .. spec[2], { locked = true })
end
for _, spec in ipairs({{"J","2%-"},{"Down","2%-"},{"K","2%+"},{"Up","2%+"},{"mouse_up","1%+"},{"mouse_down","1%-"}}) do
    command("CTRL + ALT + " .. spec[1], "wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. spec[2] .. " -l 1.5", "Media: Adjust volume", {
        locked = true, repeating = not spec[1]:match("^mouse_"),
    })
end

-- unbind clears every submap: replace the entry before registering the escape.
bind("SUPER + SHIFT + ALT + P", function() hl.dispatch(hl.dsp.submap("clean")) end, "Session: Disable shortcuts (press again to restore)")
hl.define_submap("clean", function()
    hl.bind("SUPER + SHIFT + ALT + P", function() hl.dispatch(hl.dsp.submap("reset")) end, { submap_universal = true })
end)
-- Alt+Tab stays with each shell's own implementation.

personal.bind({close=close_window})
personal.relocate()
