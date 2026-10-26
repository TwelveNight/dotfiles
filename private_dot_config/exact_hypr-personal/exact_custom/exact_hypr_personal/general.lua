-- Your own changes. Loaded after the defaults in hyprland/general.lua; never overwritten.
hl.config({
    general = { gaps_in = 10, gaps_out = 11, border_size = 3 },
    decoration = {
        rounding = 18, rounding_power = 4,
        blur = { xray = false, special = true, size = 10, passes = 3, vibrancy = 0.2, vibrancy_darkness = 0.2 },
    },
    input = { touchpad = { natural_scroll = true, clickfinger_behavior = true } },
    cursor = { no_hardware_cursors = true },
})
-- Sunshine/Moonlight touch must map to the streamed laptop display.
hl.device({ name = "libvirtualhid-touchscreen", output = "eDP-2" })
require("hypr_personal.gestures")
require("hypr_personal.hyprglass")
