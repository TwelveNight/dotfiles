-- Exact title supplied by Hermes' pet-overlay window, never by its main window.
hl.window_rule({
    name = "hermes-pet-overlay",
    match = { class = "^hermes$", title = "^Hermes Pet Overlay$" },
    float = true,
    pin = true,
    decorate = false,
    border_size = 0,
    rounding = 0,
    no_shadow = true,
    no_blur = true,
    no_dim = true,
    no_follow_mouse = true,
})

-- A runtime title arrives after mapping. Static float/pin effects do not
-- re-evaluate on title changes, so promote only this exact-title window.
local function promote_pet(window)
    if not window or window.class ~= "hermes" or window.title ~= "Hermes Pet Overlay" then
        return
    end
    if not window.floating then
        hl.dispatch(hl.dsp.window.float({ window = window, action = "set" }))
    end
    if not window.pinned then
        hl.dispatch(hl.dsp.window.pin({ window = window, action = "set" }))
    end
end

hl.on("window.title", promote_pet)
for _, window in ipairs(hl.get_windows()) do
    promote_pet(window)
end
