-- Your own changes. Loaded after the defaults in hyprland/variables.lua; never overwritten.
local launch = "bash ~/.config/hypr-personal/scripts/launch_first_available.sh"
-- Keep qsConfig/QS/QS_IPC pointing at SekaiPop.
terminalName = "kitty"
terminal = launch .. " 'kitty -1' 'foot' 'alacritty' 'wezterm' 'konsole' 'kgx' 'xterm'"
hl.env("TERMINAL", terminalName)
browser = launch .. " 'firefox' 'google-chrome-stable' 'zen-browser' 'brave' 'chromium' 'librewolf'"
codeEditor = launch .. " 'windsurf' 'antigravity' 'code' 'codium' 'cursor' 'zed' 'kate' 'gnome-text-editor' 'emacs' 'command -v nvim && kitty -1 nvim'"
taskManager = launch .. " 'command -v btop && kitty -1 -e btop' 'gnome-system-monitor' 'plasma-systemmonitor --page-name Processes'"

workspaceGroupSize = 10
require("hypr_personal").options.browser=browser

fileManager = launch .. " 'dolphin' 'nautilus' 'nemo' 'thunar' 'kitty -1 fish -c yazi'"
officeSoftware = launch .. " 'wps' 'onlyoffice-desktopeditors' 'libreoffice'"
textEditor = launch .. " 'kate' 'gnome-text-editor' 'emacs'"
volumeMixer = launch .. " 'pavucontrol-qt' 'pavucontrol'"
