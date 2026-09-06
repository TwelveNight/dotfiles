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
-- keymap.set("i", "kj", "<Esc>")

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
keymap.set("i", "<C-k>", "<Up>", { noremap = true, silent = true, desc = "up" })
keymap.set("i", "<C-h>", "<Left>", { noremap = true, silent = true, desc = "left" })
keymap.set("i", "<C-l>", "<Right>", { noremap = true, silent = true, desc = "right" })
keymap.set("i", "<C-g>", "<C-o>$", { noremap = true, silent = true, desc = "home" })
keymap.set("i", "<C-b>", "<C-o>^", { noremap = true, silent = true, desc = "home" })
keymap.set("i", "<C-]>", "<Del>", { noremap = true, silent = true, desc = "backspace" })
keymap.set("i", "<C-_>", "<BS>", { noremap = true, silent = true, desc = "backspace" })

-- vim.keymap.set("i", "<C-_>", function()
--   require("Comment.api").toggle.linewise.current()
-- end, { noremap = true, silent = true })

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
