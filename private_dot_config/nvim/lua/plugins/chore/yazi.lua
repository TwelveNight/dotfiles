return {
  -- {
  --   "DreamMaoMao/yazi.nvim",
  --   dependencies = {
  --     "nvim-telescope/telescope.nvim",
  --     "nvim-lua/plenary.nvim",
  --   },
  --
  --   keys = {
  --     { "<leader>gy", "<cmd>Yazi<CR>", desc = "Toggle Yazi" },
  --     { "<a-u>", "<cmd>Yazi<CR>", desc = "Toggle Yazi" },
  --     { "<leader>a", "<cmd>Yazi<CR>", desc = "Toggle Yazi" },
  --   },
  -- },

  --@type LazySpec
  {
    "mikavilpas/yazi.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    event = "VeryLazy",

    keys = {
      {
        -- 👇 choose your own keymapping
        "<a-u>",
        function()
          require("yazi").yazi()
        end,
        { desc = "Open the file manager" },
      },
    },
    --@type YaziConfig
    opts = {
      open_for_directories = false,
    },
  },
}
