hl.on("hyprland.start", function()
    -- hyprpm's enabled flag is persistent state, not a load request. Load
    -- enabled plugins, then reload the Lua configuration so plugin-specific
    -- settings are applied after the plugin becomes available.
    hl.exec_cmd("sleep 1 && hyprpm reload && hyprctl reload")

    -- Keep HyprGlass' theme variant synchronized with Quickshell.
    hl.exec_cmd("$HOME/.config/hypr/scripts/hyprglass-theme-sync.sh --watch >/dev/null 2>&1 &")

    -- Hyprland does not consume XDG autostart desktop files by itself, so
    -- start the input method explicitly.  Keep the guard for sessions where
    -- another launcher has already started it.
    hl.exec_cmd("pgrep -x fcitx5 >/dev/null || fcitx5 -d")
    hl.exec_cmd("libinput-gestures")

    -- Tray applications must start after Quickshell owns the watcher;
    -- hl.exec_cmd calls are asynchronous, so source order alone is not a
    -- startup ordering guarantee.
    local tray_ready = "until busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1; do sleep 0.2; done; "
    hl.exec_cmd(tray_ready .. "pgrep -x 1password >/dev/null || 1password --silent --no-sandbox")
    hl.exec_cmd(tray_ready .. "pgrep -x cc-switch >/dev/null || cc-switch")
    -- Disabled for testing: Hyprland's built-in XWayland may provide better
    -- X11-to-X11 drag-and-drop compatibility.
    -- hl.exec_cmd("xwayland-satellite")
    hl.exec_cmd(tray_ready .. "pgrep -x clash-verge >/dev/null || $HOME/.local/scripts/clash-verge-safe run --silent --no-sandbox --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime")
end)
