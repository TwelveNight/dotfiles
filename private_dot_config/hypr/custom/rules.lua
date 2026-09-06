-- Float rules
hl.window_rule({match = {class = "^(1password)$"},                float = true})
hl.window_rule({match = {class = "^(yesplaymusic)$"},             float = true})
hl.window_rule({match = {class = "^(QQ)$"},                       float = true})
hl.window_rule({match = {class = "^(Feishu)$"},                   float = true})
hl.window_rule({match = {class = "^(org.telegram.desktop)$"},     float = true})
hl.window_rule({match = {class = "^(WebCord)$"},                  float = true})
hl.window_rule({match = {class = "^(wechat)$"},                   float = true})
hl.window_rule({match = {class = "^(feh)$"},                      float = true})
hl.window_rule({match = {class = "^(wemeetapp)$"},                float = true})
hl.window_rule({match = {class = "^(xdg-desktop-portal-gtk)$"},   float = true})
hl.window_rule({match = {class = "^(pavucontrol-qt)$"},           float = true})

-- Clash Verge
hl.window_rule({match = {class = "^(clash-verge)$"}, float = true})
hl.window_rule({match = {class = "^(clash-verge)$"}, size = {"(monitor_w*0.40)", "(monitor_h*0.60)"}})
hl.window_rule({match = {class = "^(clash-verge)$"}, center = true})

-- Monitor Layout script
hl.window_rule({match = {class = "^(monitor_layout)$"}, float = true})

-- Waypaper
hl.window_rule({match = {class = "^(waypaper)$"}, float = true})

-- Brave specific window
hl.window_rule({match = {class = "^(brave-cdonnmffkdaoajfknoeeecmchibpmkmg-Default)$"}, float = true})

-- Sparkle
hl.window_rule({match = {class = "^(sparkle)$"}, float = true})
hl.window_rule({match = {class = "^(sparkle)$"}, size = {"(monitor_w*0.40)", "(monitor_h*0.60)"}})
hl.window_rule({match = {class = "^(sparkle)$"}, center = true})

-- Mihomo Party
hl.window_rule({match = {class = "^(mihomo-party)$"}, float = true})
hl.window_rule({match = {class = "^(mihomo-party)$"}, size = {"(monitor_w*0.40)", "(monitor_h*0.60)"}})
hl.window_rule({match = {class = "^(mihomo-party)$"}, center = true})

-- Firefox Nightly
hl.window_rule({match = {initial_title = "^(Firefox Nightly)$"}, size = {"(monitor_w*0.40)", "(monitor_h*0.50)"}})
hl.window_rule({match = {initial_title = "^(Firefox Nightly)$"}, center = true})

-- Brave Untitled
hl.window_rule({match = {initial_title = "^(Untitled - Brave)$"}, float = true})
hl.window_rule({match = {initial_title = "^(Untitled - Brave)$"}, size = {"(monitor_w*0.40)", "(monitor_h*0.50)"}})
hl.window_rule({match = {initial_title = "^(Untitled - Brave)$"}, center = true})

-- JetBrains IDEs
hl.window_rule({match = {class = "^(jetbrains-.*)$", title = "^(splash)$"}, center = true, float = true, no_focus = true, border_size = 0})
hl.window_rule({match = {class = "^(jetbrains-.*)$", title = "^( )$"},      center = true, float = true, stay_focused = true, border_size = 0})
hl.window_rule({match = {class = "^(jetbrains-.*)$", title = "^(win.*)$"},  no_focus = true, float = true})

-- WPS Office
hl.window_rule({match = {class = "^(wps|et|wpp|pdf)$"}, float = true})
-- 注：原 `move onscreen cursor` 在 lua API 中无直接对应，暂时省略（WPS 窗口弹出位置问题）
hl.window_rule({match = {title = "^(字体)$",     class = "^(wps|et|wpp|pdf)$"}, float = true})
hl.window_rule({match = {title = "^(查找和替换)$", class = "^(wps|et|wpp|pdf)$"}, float = true})

-- Layer rules
hl.layer_rule({match = {namespace = "vicinae"}, blur = true, ignore_alpha = 0})
