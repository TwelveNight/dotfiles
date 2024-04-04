export const keybindList = [
  [
    {
      icon: "pin_drop",
      name: "Workspaces: navigation",
      binds: [
        { keys: ["", "+", "#"], action: "Go to workspace #" },
        { keys: ["", "+", "S"], action: "Toggle special workspace(pypr)" },
        { keys: ["", "+", "(Scroll ↑↓)"], action: "Go to workspace -1/+1" },
        {
          keys: ["Ctrl", "", "+", "←"],
          action: "Go to workspace on the left",
        },
        {
          keys: ["Ctrl", "", "+", "→"],
          action: "Go to workspace on the right",
        },
        { keys: ["", "+", "PageUp"], action: "Go to workspace on the left" },
        {
          keys: ["", "+", "PageDown"],
          action: "Go to workspace on the right",
        },
      ],
      id: 1,
    },
    {
      icon: "overview_key",
      name: "Workspaces: management",
      binds: [
        { keys: ["", "Alt", "+", "#"], action: "Move window to workspace #" },
        {
          keys: ["", "Alt", "+", "S"],
          action: "Move window to special workspace(pypr)",
        },
        {
          keys: ["", "Alt", "+", "PageUp"],
          action: "Move window to workspace on the left",
        },
        {
          keys: ["", "Alt", "+", "PageDown"],
          action: "Move window to workspace on the right",
        },
      ],
      id: 2,
    },
    {
      icon: "move_group",
      name: "Windows",
      binds: [
        { keys: ["", "+", "←↑→↓"], action: "Focus window in direction" },
        {
          keys: ["", "Shift", "+", "←↑→↓"],
          action: "Resize window in direction",
        },
        { keys: ["", "+", ";"], action: "Split ratio -" },
        { keys: ["", "+", "'"], action: "Split ratio +" },
        { keys: ["", "+", "hjkl"], action: "Move window" },
        { keys: ["", "Shift", "+", "hjkl"], action: "Resize window" },
        { keys: ["", "+", "O"], action: "Fullscreen 1" },
        { keys: ["", "Alt", "+", "O"], action: "Fullscreen 0" },
        { keys: ["", "Alt", "+", "F"], action: "Fake fullscreen" },
        { keys: ["", "Ctrl", "+", "P"], action: "Pin a window" },
      ],
      id: 3,
    },
  ],
  [
    {
      icon: "widgets",
      name: "Widgets (AGS)",
      binds: [
        {
          keys: ["", "OR", "", "+", "Tab"],
          action: "Toggle overview/launcher",
        },
        {
          keys: ["Ctrl", "", "+", "R", "OR", "Ctrl", "Shift", "+", "R"],
          action: "Restart AGS",
        },
        {
          keys: ["Ctrl", "", "Alt", "+", "R"],
          action: "Restart AGS and reload hyprland",
        },
        { keys: ["", "+", "/"], action: "Toggle this cheatsheet" },
        { keys: ["", "+", "B"], action: "Toggle system sidebar" },
        {
          keys: ["", "+", "U"],
          action: "Toggle utilities sidebar",
        },
        {
          keys: ["Ctrl", "Shift", "", "+", "K"],
          action: "Toggle virtual keyboard",
        },
        {
          keys: ["Ctrl", "Alt", "+", "Del", "OR", "", "+", "Back"],
          action: "Power/Session menu",
        },

        {
          keys: ["", "+", "Q", "OR", "Ctrl", "Shift", "+", "Q"],
          action: "Exit a window",
        },
        { keys: ["Esc"], action: "Dismiss/close sidebar" },

        {
          keys: ["Ctrl", "", "+", "T"],
          action: "Change wallpaper+colorscheme",
        },
        {
          keys: ["", "Shift", "+", "W"],
          action: "Change wallpaper+colorscheme",
        },

        // { "keys": ["", "+", "B"], "action": "Toggle left sidebar" },
        // { "keys": ["", "+", "N"], "action": "Toggle right sidebar" },
        // { "keys": ["", "+", "G"], "action": "Toggle volume mixer" },
        // { "keys": ["", "+", "M"], "action": "Toggle useless audio visualizer" },
        // { "keys": ["(right)Ctrl"], "action": "Dismiss notification & close menus" }
      ],
      id: 4,
    },
    {
      icon: "construction",
      name: "Utilities",
      binds: [
        { keys: ["PrtSc"], action: "Screenshot  >>  clipboard" },
        {
          keys: ["Ctrl", "Alt", "+", "A/Lmb"],
          action: "Screen snip  >>  clipboard",
        },
        {
          keys: ["Ctrl", "Alt", "+", "I/Mmb"],
          action: "Pin a screenshot",
        },
        {
          keys: ["CTRL", "Alt", "+", "X"],
          action: "Image to text (pot)",
        },
        {
          keys: ["CTRL", "Alt", "+", "C"],
          action: "Translate image (pot)",
        },
        { keys: ["", "Shift", "+", "C"], action: "Color picker" },
        { keys: ["", "Alt", "+", "R"], action: "Record region" },
        { keys: ["Ctrl", "Alt", "+", "R"], action: "Record region with sound" },
        {
          keys: ["", "Shift", "Alt", "+", "R"],
          action: "Record screen with sound",
        },
      ],
      id: 5,
    },
  ],
  [
    {
      icon: "apps",
      name: "Apps",
      binds: [
        { keys: ["", "+", "A"], action: "Launch terminal: kitty(scratchpad)" },
        {
          keys: ["", "+", "F"],
          action: "Launch browser: Firefox(scratchpad)",
        },
        {
          keys: ["Ctrl", "Shift", "+", "S"],
          action: "Launch browser: Thorium",
        },
        { keys: ["", "+", "C"], action: "Launch editor: vscode" },
        { keys: ["", "+", "X"], action: "Launch editor: GNOME Text Editor" },
        {
          keys: ["Ctrl", "", "+", "I"],
          action: "Launch settings: GNOME Control center",
        },
        {
          keys: ["Ctrl", "Alt", "Shift", "+", "I"],
          action: "Launch settings: kde system settings",
        },
      ],
      id: 6,
    },
    {
      icon: "keyboard",
      name: "Typing",
      binds: [
        { keys: ["", "+", "V"], action: "Clipboard history  >>  clipboard" },
        { keys: ["", "+", "."], action: "Emoji picker  >>  clipboard" },
      ],
      id: 7,
    },
    {
      icon: "terminal",
      name: "Launcher actions",
      binds: [
        { keys: [">raw"], action: "Toggle mouse acceleration" },
        { keys: [">img"], action: "Select wallpaper and generate colorscheme" },
        { keys: [">light"], action: "Switch to light theme" },
        { keys: [">dark"], action: "Switch to dark theme" },
        { keys: [">badapple"], action: "Apply black n' white colorscheme" },
        { keys: [">color"], action: "Pick acccent color" },
        {
          keys: [">todo"],
          action: "Type something after that to add a To-do item",
        },
      ],
      id: 8,
    },
  ],
];
