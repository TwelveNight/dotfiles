return {
  "kevinhwang91/rnvimr",
  cmd = "RnvimrToggle",
  lazy = true,
  config = function()
    vim.g.rnvimr_draw_border = 1
    vim.g.rnvimr_pick_enable = 1
    vim.g.rnvimr_bw_enable = 1
  end,
  keys = {
    { "<M-u>", ":RnvimrToggle<CR>", desc = "ranger toggle" },
    { "<M-u>", "<C-\\><C-n><cmd>RnvimrToggle<CR>", mode = { "t" }, desc = "Rnvimr Toggle" },
    { "<M-t>", "<C-\\><C-n>:RnvimrResize<CR>" },
  },
}
