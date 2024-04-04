-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

if vim.g.neovide then
  -- Set IME input
  vim.g.neovide_input_ime = true

  local function set_ime(args)
    if args.event:match("Enter$") then
      vim.g.neovide_input_ime = true
    else
      vim.g.neovide_input_ime = false
    end
  end

  local ime_input = vim.api.nvim_create_augroup("ime_input", { clear = true })

  vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
    group = ime_input,
    pattern = "*",
    callback = set_ime,
  })

  vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave" }, {
    group = ime_input,
    pattern = "[/\\?]",
    callback = set_ime,
  })

  -- Set cursor particle effect
  vim.g.neovide_cursor_vfx_mode = "pixiedust"
end

-- fix C-i and Tab key in kitty
if vim.env.TERM == "xterm-kitty" then
  vim.cmd([[autocmd UIEnter * if v:event.chan ==# 0 | call chansend(v:stderr, "\x1b[>1u") | endif]])
  vim.cmd([[autocmd UILeave * if v:event.chan ==# 0 | call chansend(v:stderr, "\x1b[<1u") | endif]])

  vim.cmd("nnoremap <c-i> <c-i>")
  vim.cmd("nnoremap <ESC>[105;5u <C-I>")
  vim.cmd("nnoremap <Tab>        %")
  vim.cmd("noremap  <ESC>[88;5u  :!echo B<CR>")
  vim.cmd("noremap  <ESC>[49;5u  :!echo C<CR>")
  vim.cmd("noremap  <ESC>[1;5P   :!echo D<CR>")
end
