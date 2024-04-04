return {
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = "markdown",
    config = function()
      vim.g.mkdp_auto_start = 1
    end,
    keys = {
      { "<leader>wp", "<cmd>MarkdownPreview<cr>" },
      { "<leader>wq", "<cmd>MarkdownPreviewStop<cr>" },
    },
  },
}
