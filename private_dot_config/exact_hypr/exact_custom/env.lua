-- NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- Hybrid graphics: render primarily on the GPU driving the HDMI output.
hl.env("AQ_DRM_DEVICES", "/home/night/.config/hypr/custom/nvidia-drm-card:/home/night/.config/hypr/custom/amd-drm-card")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("WLR_DRM_NO_ATOMIC", "1")
hl.env("__GL_VRR_ALLOWED", "1")

-- Input method (fcitx5)
-- Native Wayland clients use the compositor's text-input protocol. Keep the
-- legacy GTK/Qt/SDL modules out of the global Hyprland environment.
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("GTK_IM_MODULE", "")
hl.env("QT_IM_MODULE", "")
hl.env("SDL_IM_MODULE", "")
hl.env("INPUT_METHOD", "")

-- Editor
hl.env("EDITOR", "nvim")

-- Keep the black cursor theme consistent from compositor startup onward.
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
