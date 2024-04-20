const userConfigOptions = {
  // For every option, see ~/.config/ags/modules/.configuration/user_options.js
  // (vscode users ctrl+click this: file://./modules/.configuration/user_options.js)
  // (vim users: `:vsp` to split window, move cursor to this path, press `gf`. `Ctrl-w` twice to switch between)
  //   options listed in this file will override the default ones in the above file
  // Here's an example

  ai: {
    defaultGPTProvider: "zukijourney",
    defaultTemperature: 0.9,
    enhancements: true,
    useHistory: true,
    writingCursor: " ...", // Warning: Using weird characters can mess up Markdown rendering
  },

  appearance: {
    keyboardUseFlag: false, // Use flag emoji instead of abbreviation letters
    layerSmoke: false,
    layerSmokeStrength: 0.2,
    fakeScreenRounding: true,
  },

  apps: {
    bluetooth: "blueberry",
    imageViewer: "loupe",
    network: 'XDG_CURRENT_DESKTOP="gnome" gnome-control-center wifi',
    settings: 'XDG_CURRENT_DESKTOP="gnome" gnome-control-center wifi',
    taskManager: "gnome-usage",
    terminal: "kitty", // This is only for shell actions
  },

  dock: {
    enabled: false,
    hiddenThickness: 5,
    pinnedApps: ["firefox", "org.gnome.Nautilus"],
    layer: "top",
    monitorExclusivity: true, // Dock will move to other monitor along with focus if enabled
    searchPinnedAppIcons: false, // Try to search for the correct icon if the app class isn't an icon name
    trigger: ["client-added", "client-removed"], // client_added, client_move, workspace_active, client_active
    // Automatically hide dock after `interval` ms since trigger
    autoHide: [
      {
        trigger: "client-added",
        interval: 500,
      },
      {
        trigger: "client-removed",
        interval: 500,
      },
    ],
  },

  time: {
    // See https://docs.gtk.org/glib/method.DateTime.format.html
    // Here's the 12h format: "%I:%M%P"
    // For seconds, add "%S" and set interval to 1000
    format: "%H:%M",
    interval: 5000,
    dateFormatLong: "%A, %m/%d", // On bar
    dateInterval: 5000,
    dateFormat: "%m/%d", // On notif time
  },

  weather: {
    city: "shanghai",
  },

  icons: {
    // Find the window's icon by its class with levenshteinDistance
    // The file names are processed at startup, so if there
    // are too many files in the search path it'll affect performance
    // Example: ['/usr/share/icons/Tela-nord/scalable/apps']
    // searchPaths: ["/usr/share/icons/fluent11/symbolic/apps"],

    substitutions: {
      "code-url-handler": "visual-studio-code",
      Code: "visual-studio-code",
      "GitHub Desktop": "github-desktop",
      "Minecraft* 1.20.1": "minecraft",
      "gnome-tweaks": "org.gnome.tweaks",
      "pavucontrol-qt": "pavucontrol",
      wps: "wps-office2019-kprometheus",
      wpsoffice: "wps-office2019-kprometheus",
      "": "image-missing",
      firefoxnightly: "firefox-nightly",
      "codium-url-handler": "vscodium",
    },
  },

  keybinds: {
    // Format: Mod1+Mod2+key. CaSe SeNsItIvE!
    // Modifiers: Shift Ctrl Alt Hyper Meta
    // See https://docs.gtk.org/gdk3/index.html#constants for the other keys (they are listed as KEY_key)
    overview: {
      altMoveLeft: "Ctrl+h",
      altMoveRight: "Ctrl+l",
      deleteToEnd: "Ctrl+k",
    },
    sidebar: {
      apis: {
        nextTab: "Page_Down",
        prevTab: "Page_Up",
      },
      options: {
        // Right sidebar
        nextTab: "Page_Down",
        prevTab: "Page_Up",
      },
      pin: "Ctrl+p",
      cycleTab: "Ctrl+Tab",
      nextTab: "Ctrl+Page_Down",
      prevTab: "Ctrl+Page_Up",
    },
    cheatsheet: {
      nextTab: "Page_Down",
      prevTab: "Page_Up",
    },
  },
};

export default userConfigOptions;
