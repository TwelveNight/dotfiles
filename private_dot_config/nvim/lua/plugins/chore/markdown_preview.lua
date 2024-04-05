return {
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = "markdown",
    config = function()
      vim.g.mkdp_auto_start = 1
    end,
    keys = {
      { "<leader>wp", "<cmd>MarkdownPreview<cr>", desc = "Start markdown preview" },
      { "<leader>wq", "<cmd>MarkdownPreviewStop<cr>", desc = "Stop markdown preview" },
    },
  },
}
