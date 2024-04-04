return {
  {
    "folke/tokyonight.nvim",
    require("notify").setup({
      background_colour = "#000000",
    }),
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
}
