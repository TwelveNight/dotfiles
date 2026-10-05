-- cursor 配置目前无需覆盖
-- 如需启用 no_hardware_cursors，取消注释：
-- hl.config({ cursor = { no_hardware_cursors = true } })

-- Map Sunshine/Moonlight absolute touch input to the streamed display.
-- Without an explicit output, Hyprland maps it across the full monitor layout.
hl.device({
	name = "libvirtualhid-touchscreen",
	output = "eDP-2",
})

-- Four-finger swipes are owned by the upstream window-move gesture.
-- Five-finger down toggles search; five-finger up toggles maximization.
hl.gesture({
    fingers = 5,
    direction = "down",
    action = function()
        -- A gesture has no key-release phase, so use the Quickshell IPC
        -- toggle directly instead of the Super release-sensitive shortcut.
        hl.dispatch(hl.dsp.exec_cmd("qs -c ii ipc call search toggle"))
    end
})

hl.gesture({
    fingers = 5,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.window.fullscreen({mode = "maximized", action = "toggle"}))
    end
})
