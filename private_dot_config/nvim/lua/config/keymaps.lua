-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Scroll document/enter document
-- (<c-f>/<c-b>) / K one more time to enter the docs

-- local noremap = true, silent = true = { noremap = true, silent = true }
-- back
keymap.set("i", "jk", "<Esc>")

-- Center C-d and C-u
keymap.set("n", "<C-d>", "<C-d>zz", opts)
keymap.set("n", "<C-u>", "<C-u>zz", opts)

-- Center search results
keymap.set("n", "n", "nzzzv", opts)
keymap.set("n", "N", "Nzzzv", opts)

keymap.set("n", "W", "%", opts)

-- quit
-- keymap.set("n", "q", "<cmd>:q<cr>", { noremap = true, silent = true, desc = "quit" })
keymap.set("n", "<C-q>", "<cmd>:q<cr>", { noremap = true, silent = true, desc = "Quit window" })
keymap.set("n", "Q", "<cmd>bdelete<cr>", { desc = "Kill Buffer" })

-- move
keymap.set("i", "<C-j>", "<Down>", { noremap = true, silent = true, desc = "down" })
keymap.set("i", "<C-p>", "<Up>", { noremap = true, silent = true, desc = "up" })
keymap.set("i", "<C-h>", "<Left>", { noremap = true, silent = true, desc = "left" })
keymap.set("i", "<C-l>", "<Right>", { noremap = true, silent = true, desc = "right" })
keymap.set("i", "<C-e>", "<End>", { noremap = true, silent = true, desc = "end" })
keymap.set("i", "<C-a>", "<Home>", { noremap = true, silent = true, desc = "home" })

-- move line left or right
keymap.set("n", "H", "^", { desc = "end" })
keymap.set("n", "L", "$", { desc = "home" })
keymap.set("v", "H", "^", { desc = "end" })
keymap.set("v", "L", "$", { desc = "home" })

-- Split window
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)

-- Redo
keymap.set("n", "U", "<C-r>", { noremap = true, silent = true, desc = "Redo" })

-- buffer
keymap.set("n", "tp", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
keymap.set("n", "tn", "<cmd>bnext<cr>", { desc = "Next buffer" })
keymap.set("n", "E", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
keymap.set("n", "R", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- indent block
-- keymap.set("n", "<TAB>", ">>", { silent = true, desc = "Indent left" })
keymap.set("n", "<S-TAB>", "<<", { silent = true, desc = "Indent left" })
keymap.set("v", "<TAB>", ">gv", { silent = true, desc = "Indent left" })
keymap.set("v", "<S-TAB>", "<gv", { silent = true, desc = "Indent left" })
-- fix <C-I> mapping
keymap.set("n", "<C-I>", "<C-I>")
-- keymap.set("n", "<TAB>", "<C-I>")
keymap.set("n", "<C-m>", "<C-i>", opts)

-- Move Lines
keymap.set("v", "<S-j>", ":m '>+1<cr>gv=gv", { silent = true, desc = "Move down" })
keymap.set("v", "<S-k>", ":m '<-2<cr>gv=gv", { silent = true, desc = "Move up" })

-- sniprun
keymap.set("n", "<leader>rs", ":%SnipRun<cr>", { noremap = true, silent = true, desc = "sniprun" })
keymap.set("v", "<leader>rs", ":%SnipRun<cr>", { noremap = true, silent = true, desc = "sniprun" })
keymap.set("n", "<leader>rc", "<cmd>SnipClose<cr>", { noremap = true, silent = true, desc = "snipclose" })
keymap.set("v", "<leader>rc", ":<cmd>SnipClose<cr>", { noremap = true, silent = true, desc = "snipclose" })

-- chatgpt
--keymap.set("n", "<leader>ge", "<cmd>ChatGPTEditWithInstructions<cr>")

-- copilot
keymap.set(
  "n",
  "<leader>Ga",
  ":lua require('copilot.suggestion').accept()<cr>",
  { noremap = true, silent = true, desc = "Accept" }
)
keymap.set(
  "n",
  "<leader>Gn",
  ":lua require('copilot.suggestion').next()<cr>",
  { noremap = true, silent = true, desc = "Next" }
)
keymap.set(
  "n",
  "<leader>Gp",
  ":lua require('copilot.suggestion').prev()<cr>",
  { noremap = true, silent = true, desc = "Prev" }
)
keymap.set(
  "n",
  "<leader>Gs",
  ":lua require('copilot.suggestion').dismiss()<cr>",
  { noremap = true, silent = true, desc = "Dismiss" }
)
keymap.set(
  "n",
  "<leader>Gt",
  ":lua require('copilot.suggestion').toggle_auto_trigger()<cr>",
  { noremap = true, silent = true, desc = "Toggle Auto Trigger" }
)
keymap.set("n", "<leader>Ge", ":Copilot enable<cr>", { noremap = true, silent = true, desc = "Enable the Copilot" })
keymap.set("n", "<leader>Gd", ":Copilot disable<cr>", { noremap = true, silent = true, desc = "disable the Copilot" })

-- set telescope keymaps
keymap.set(
  "n",
  "<leader>sx",
  require("telescope.builtin").resume,
  { noremap = true, silent = true, desc = "Resume Last Telescope Picker" }
)

-- translate
-- <C-w>p to into the translation window
keymap.set({ "n" }, "<leader>Tn", "<Plug>Translate", { silent = true, desc = "Translate Word in Nocie" })
keymap.set({ "v" }, "<leader>Tn", "<Plug>TranslateV", { silent = true, desc = "Translate Word in Nocie" })
keymap.set({ "n" }, "<leader>Tt", "<Plug>TranslateW", { silent = true, desc = "Translate Word in Window" })
keymap.set({ "v" }, "<leader>Tt", "<Plug>TranslateWV", { silent = true, desc = "Translate Word in Window" })
keymap.set(
  { "n" },
  "<leader>Tr",
  ":TranslateR --target_lang=english<cr>",
  { silent = true, desc = "Translate Word and Replace the word" }
)
keymap.set(
  { "v" },
  "<leader>Tr",
  ":TranslateR --target_lang=english<cr>",
  { silent = true, desc = "Translate Word and Replace the word" }
)
keymap.set(
  { "n" },
  "<leader>Tx",
  "<Plug>TranslateX",
  { silent = true, desc = "Translate Word and Write to the clipboard" }
)
keymap.set(
  { "v" },
  "<leader>Tx",
  "<Plug>TranslateXV",
  { silent = true, desc = "Translate Word and Write to the clipboard" }
)

-- debug
-- NOTE: c/c++ debug neeg -g flag to instructs the compiler to generate debug letters
keymap.set("n", "<F4>", function()
  require("dap").terminate()
end, { noremap = true, silent = true, desc = "terminate" })

keymap.set("n", "<F5>", function()
  require("dap").continue()
end, { noremap = true, silent = true, desc = "continue" })

keymap.set("n", "<F6>", function()
  require("dap").step_over()
end, { noremap = true, silent = true, desc = "step_over" })

keymap.set("n", "<F7>", function()
  require("dap").step_into()
end, { noremap = true, silent = true, desc = "step_into" })

keymap.set("n", "<F8>", function()
  require("dap").step_out()
end, { noremap = true, silent = true, desc = "step_out" })

keymap.set("n", "<F9>", function()
  require("dap").run_last()
end, { noremap = true, silent = true, desc = "run last" })

keymap.set("n", "<F10>", function()
  require("dap").restart()
end, { noremap = true, silent = true, desc = "restart" })

-- lspsaga
keymap.set("n", "<leader>k", "<cmd>Lspsaga hover_doc<CR>", { noremap = true, silent = true, desc = "hover_doc" })
keymap.set(
  "n",
  "<leader>ci",
  "<cmd>:Lspsaga incoming_calls<cr>",
  { noremap = true, silent = true, desc = "incoming_calls" }
)
keymap.set(
  "n",
  "<leader>co",
  "<cmd>Lspsaga outgoing_calls<cr>",
  { noremap = true, silent = true, desc = "outgoing_calls" }
)

-- Launch lazygit as full screen
local Util = require("lazyvim.util")
keymap.set("n", "<leader>gg", function()
  Util.terminal.open({ "lazygit" }, {
    size = {
      width = 1,
      height = 1,
    },
    border = "none",
  })
end, { desc = "Lazygit" })

-- 初始化全局变量 enc_index
local enc_index = 0

-- 定义函数 ChangeFileencoding
function ChangeFileencoding()
  -- 编码列表
  local encodings = { "GBK", "koi8-u", "cp866" }

  -- 构建命令字符串
  local command = string.format("e ++enc=%s %%:p", encodings[enc_index + 1])

  -- 执行命令
  vim.cmd(command)

  -- 更新 enc_index
  enc_index = (enc_index + 1) % 3
end

-- 将函数映射到 F8 键
vim.api.nvim_set_keymap("n", "<F11>", ":lua ChangeFileencoding()<CR>", { noremap = true, silent = true })
