return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        window = {
          mappings = {
            ["."] = "toggle_hidden",
            ["H"] = "set_root",
          },
        },
      },
      window = {
        mappings = {
          ["l"] = "open",
          ["o"] = "open",
          ["h"] = "close_node",
        },
      },
    },
    keys = {
      {
        "<leader>P",
        "<cmd>Neotree reveal_force_cwd<cr>",
        desc = "Explorer Neotree (reveal)",
      },
    },
  },
}
