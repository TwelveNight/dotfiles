-- Your own changes. Loaded after the defaults in hyprland/env.lua; never overwritten.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__GL_VRR_ALLOWED", "1")
-- PCI aliases contain ':' (Aquamarine's separator). Resolve them to today's
-- card numbers rather than copying device symlinks or hardcoding card2/card1.
local cards = {}
for _, pci in ipairs({"0000:01:00.0", "0000:06:00.0"}) do
    local pipe = io.popen("readlink -e /dev/dri/by-path/pci-" .. pci .. "-card 2>/dev/null")
    if pipe then
        local card = pipe:read("*l")
        pipe:close()
        if card and card:match("^/dev/dri/card%d+$") then cards[#cards + 1] = card end
    end
end
if #cards > 0 then hl.env("AQ_DRM_DEVICES", table.concat(cards, ":")) end

-- Native Wayland input uses text-input; XWayland uses XIM.
hl.env("XMODIFIERS", "@im=fcitx")
for _, name in ipairs({"GTK_IM_MODULE", "QT_IM_MODULE", "SDL_IM_MODULE", "INPUT_METHOD"}) do
    hl.env(name, "")
end
hl.env("EDITOR", "nvim")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
