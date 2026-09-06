return {
  -- messages, cmdline and the popupmenu
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.presets.lsp_doc_border = true

      -- opts.presets = {
      --   lsp_doc_border = true,
      --   command_palette = {
      --     views = {
      --       cmdline_popup = {
      --         position = {
      --           row = "50%",
      --         },
      --       },
      --     },
      --   },
      -- }
    end,
  },
}
