-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()

    -- Input method: initialize it before graphical clients inherit the session environment.
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("dbus-update-activation-environment --systemd XMODIFIERS WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP")

    -- Bar, wallpaper
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    -- Quickshell's Qt TextInput needs the Fcitx5 Qt input method module.
    -- Keep this scoped to Quickshell; native Wayland clients use text-input-v3.
    hl.exec_cmd("env QS_NO_RELOAD_POPUP=1 QT_IM_MODULE=fcitx GTK_IM_MODULE=fcitx XMODIFIERS=@im=fcitx qs -c $qsConfig")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

    -- Core components (authentication, lock screen, notification daemon)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard: history
    --hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")
    hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
