-- cursor 配置目前无需覆盖
-- 如需启用 no_hardware_cursors，取消注释：
-- hl.config({ cursor = { no_hardware_cursors = true } })

-- Map Sunshine/Moonlight absolute touch input to the laptop display.
-- Without an explicit output, Hyprland maps it across the full monitor layout.
hl.device({
    name = "libvirtualhid-touchscreen",
    output = "eDP-1"
})

-- Replace the default four-finger swipe-down Quickshell overview gesture
-- with the same maximize toggle dispatcher as SUPER+O.
hl.gesture({
    fingers = 4,
    direction = "down",
    action = "unset"
})
hl.gesture({
    fingers = 4,
    direction = "down",
    action = function()
        hl.dispatch(hl.dsp.window.fullscreen({mode = "maximized", action = "toggle"}))
    end
})
