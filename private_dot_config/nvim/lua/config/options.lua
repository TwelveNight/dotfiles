-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt

-- opt.shell = "/bin/sh"

-- Cancel the relativenumber
-- opt.relativenumber = false

-- Enable command auto completion with Tab
opt.wildmenu = true
opt.wildmode = "longest:list,full"

-- Add the current directory to the left of the status bar
opt.winbar = "%=%m %f"

-- Foldmethod
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldlevel = 99
opt.foldenable = false

-- vim.g.root_spec = { "cwd" }
