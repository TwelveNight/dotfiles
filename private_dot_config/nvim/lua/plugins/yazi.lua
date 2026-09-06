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
        "<a-o>",
        function()
          require("yazi").yazi()
        end,
        { desc = "Open the file manager" },
      },
      {
        -- Open in the current working directory
        "<leader>cw",
        function()
          require("yazi").yazi(nil, vim.fn.getcwd())
        end,
        desc = "Open the file manager in nvim's working directory",
      },
    },
    --@type YaziConfig
    opts = {
      open_for_directories = false,
    },
  },
}
