-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.cmd([[
augroup _fold_bug_solution  " https://github.com/nvim-telescope/telescope.nvim/issues/559
    autocmd!
    autocmd BufRead * autocmd BufWinEnter * ++once normal! zx
  augroup end
]])

local util = require("lazyvim.util")

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local usercmd = vim.api.nvim_create_user_command

--[[ -------------
     AUTO COMMANDS
     ------------- ]]

-- Prefer creating groups and assigning autocmds to groups, because it makes it easier to clear them
--[[ Mygroup Group ]]
augroup("mygroup", { clear = true })

autocmd("Filetype", {
  pattern = { "*" },
  callback = function()
    -- vim.opt.formatoptions = vim.opt.formatoptions - "o"
    if vim.bo["ft"] == "css" then
      vim.opt_local.formatoptions:remove("r") -- don't enter comment leader on Enter in css files
    end
    vim.opt.formatoptions = vim.opt.formatoptions + {
      o = false, -- Don't continue comments with o and O
    }
  end,
  group = "mygroup",
  desc = "Don't continue comments with o and O",
})

-- Reload config on save
autocmd("BufWritePost", {
  -- Match all `lua` files in `lua/config` except `lazy.lua` which is the
  -- setup file for `lazy.nvim` and should only be reloaded when updated.
  pattern = "**/lua/config/*[^lazy].lua",
  callback = function()
    local filepath = vim.fn.expand("%")
    dofile(filepath)
    vim.notify("Configuration reloaded \n" .. filepath, nil)
  end,
  group = "mygroup",
  desc = "Reload config on save",
})

--[[ Remember Folds Group ]]
augroup("remember_folds", { clear = true })

autocmd({ "BufLeave", "BufWinLeave" }, {
  pattern = "*",
  callback = function()
    vim.cmd("silent! mkview")
  end,
  group = "remember_folds",
  desc = "Remember folds on buffer exit",
})

autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    vim.cmd("silent! loadview")
  end,
  group = "remember_folds",
  desc = "Restore folds on buffer enter",
})

--[[ Disable `mini.indentscope` for specific filetypes ]]
autocmd("FileType", {
  pattern = { "fzf", "lspinfo" },
  group = augroup("DisableIndentScope", { clear = true }),
  callback = function()
    vim.b.miniindentscope_disable = true
  end,
  desc = "Disable `mini.indentscope` for specific filetypes",
})
