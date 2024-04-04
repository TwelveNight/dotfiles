const userConfigOptions = {
  // For every option, see ~/.config/ags/modules/.configuration/user_options.js
  // (vscode users ctrl+click this: file://./modules/.configuration/user_options.js)
  // (vim users: `:vsp` to split window, move cursor to this path, press `gf`. `Ctrl-w` twice to switch between)
  //   options listed in this file will override the default ones in the above file
  // Here's an example
  keybinds: {
    sidebar: {
      pin: "Ctrl+p",
      nextTab: "Ctrl+Page_Down",
      prevTab: "Ctrl+Page_Up",
    },
  },

  ai: {
    defaultGPTProvider: "zukijourney",
    defaultTemperature: 0.9,
    enhancements: true,
    useHistory: true,
    writingCursor: " ...", // Warning: Using weird characters can mess up Markdown rendering
  },
  apps: {
    imageViewer: "loupe",
    terminal: "kitty", // This is only for shell actions
  },
};

export default userConfigOptions;
