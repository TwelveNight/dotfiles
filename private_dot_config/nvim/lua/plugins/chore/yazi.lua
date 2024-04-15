return {
  {
    "DreamMaoMao/yazi.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },

    keys = {
      { "<leader>gy", "<cmd>Yazi<CR>", desc = "Toggle Yazi" },
      { "<a-u>", "<cmd>Yazi<CR>", desc = "Toggle Yazi" },
      { "<leader>a", "<cmd>Yazi<CR>", desc = "Toggle Yazi" },
    },
  },
}
