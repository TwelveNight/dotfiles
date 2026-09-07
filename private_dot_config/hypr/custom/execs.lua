hl.on("hyprland.start", function()
    hl.exec_cmd("libinput-gestures")
    hl.exec_cmd("1password --silent --no-sandbox")
    hl.exec_cmd("cc-switch")
    -- Disabled for testing: Hyprland's built-in XWayland may provide better
    -- X11-to-X11 drag-and-drop compatibility.
    -- hl.exec_cmd("xwayland-satellite")
    hl.exec_cmd("sleep 2 && clash-verge --silent --no-sandbox --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime")
end)
