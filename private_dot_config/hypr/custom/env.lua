-- NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
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
