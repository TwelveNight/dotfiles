-- Shared personal behavior is owned by chezmoi, independent of this shell.
local config = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local root = os.getenv("HYPR_PERSONAL_DIR") or (config .. "/hypr-personal")
local personal = assert(loadfile(root .. "/init.lua"), "Install ~/.config/hypr-personal with chezmoi first")(root)
local actions={
    ["quickpanel toggle"]=hl.dsp.global("quickshell:sidebarLeftToggle"),
    ["launcherphone toggle"]=hl.dsp.global("quickshell:searchOnlyToggle"),
    ["overview toggle"]=hl.dsp.global("quickshell:overviewWorkspacesToggle"),
    ["keyboard toggle"]=hl.dsp.global("quickshell:oskToggle"),
    ["focus toggle"]=false,
    ["desktopedit toggle"]=hl.dsp.global("quickshell:editModeToggle"),
    ["settings toggle"]=hl.dsp.global("quickshell:settingsToggle"),
    ["wallpaperpicker toggle"]=hl.dsp.global("quickshell:wallpaperSelectorToggle"),
    ["launcher"]=hl.dsp.global("quickshell:searchOnlyToggle"),
    ["lock"]="qs -c ii ipc call lock activate; loginctl lock-session",
    ["session"]=hl.dsp.global("quickshell:sessionToggle"),
    ["screenshot"]="grim -g \"$(slurp)\" - | wl-copy",
}
local function relocations() return {
    {"CTRL + SUPER + ALT + I",hl.dsp.exec_cmd("xdg-open ~/.config/quickshell/ii/config.json"),"Shell: Edit shell config"},
    {"SUPER + CTRL + ALT + R",hl.dsp.global("quickshell:oledSaverToggle"),"Shell: Toggle OLED saver"},
    {"ALT + SHIFT + Space",hl.dsp.exec_cmd("vicinae"),"Apps: Vicinae"},
    {"SUPER + B",hl.dsp.global("quickshell:sidebarRightToggle"),"Shell: Toggle right sidebar"},
    {"SUPER + SHIFT + ALT + J",hl.dsp.global("quickshell:barToggle"),"Shell: Toggle bar"},
    {"SUPER + SHIFT + ALT + N",hl.dsp.global("quickshell:notesToggle"),"Shell: Toggle notes"},
    {"SUPER + CTRL + Space",hl.dsp.exec_cmd("hyprctl switchxkblayout all next"),"Input: Next keyboard layout"},
    {"SUPER + CTRL + ALT + P",hl.dsp.window.pin(),"Windows: Pin window"},
} end
return personal.configure({internal_output="eDP-2",actions=actions,relocations=relocations,browser=browser or "firefox",overview=function()
    hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
end})
