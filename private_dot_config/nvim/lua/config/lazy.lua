local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    opts = {
      colorscheme = "solarized-osaka",
      -- news = {
      --   lazyvim = true,
      --   neovim = true,
      -- },
    },

    -- import/override with your plugins
    { import = "plugins" },
    { import = "plugins/scheme" },
    -- { import = "plugins/code" },
    { import = "plugins/code/completion" },
    { import = "plugins/code/lsp" },
    { import = "plugins/code/lang/go" },
    { import = "plugins/code/lang/front-end" },
    { import = "plugins/code/lang/cpp" },
    { import = "plugins/code/chore" },
    { import = "plugins/code/cmp" },
    { import = "plugins/git" },
    { import = "plugins/override" },
    { import = "plugins/override/telescope" },
    { import = "plugins/chore" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "solarized-osaka", "tokyonight", "habamax" } },
  checker = { enabled = true, notify = false }, -- automatically check for plugin updates
  -- checker = { enabled = true, frequency = 86400 }
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
