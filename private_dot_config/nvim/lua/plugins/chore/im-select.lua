return {
  {
    "keaising/im-select.nvim",
    config = function()
      require("im_select").setup({
        -- not auto change back to zh after re-enter insert mode
        set_previous_events = {},
      })
    end,
  },
}
