return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "<leader>ct", "<cmd>lua vim.lsp.buf.incoming_calls()<cr>", desc = "LiteeCalltree" }
    end,
  },
  {
    "ldelossa/litee-calltree.nvim",
    dependencies = {
      {
        "ldelossa/litee.nvim",
        config = function()
          require("litee.lib").setup({
            panel = {
              orientation = "right",
              panel_size = 30,
            },
          })
        end,
      },
    },
    config = function()
      require("litee.calltree").setup({
        -- hide_cursor = false,
        resolve_symbols = false,
      })
    end,
  },
}
