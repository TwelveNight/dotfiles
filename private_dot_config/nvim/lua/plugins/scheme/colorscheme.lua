return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "neofusion",
    },
  },

  {
    "diegoulloao/neofusion.nvim",
    priority = 1000,
    config = function()
      -- Default options:
      require("neofusion").setup({
        terminal_colors = true, -- add neovim terminal colors
        undercurl = true,
        underline = true,
        bold = true,
        italic = {
          strings = true,
          emphasis = true,
          comments = true,
          operators = false,
          folds = true,
        },
        strikethrough = true,
        invert_selection = false,
        invert_signs = false,
        invert_tabline = false,
        invert_intend_guides = false,
        inverse = true, -- invert background for search, diffs, statuslines and errors
        palette_overrides = {},
        overrides = {},
        dim_inactive = false,
        transparent_mode = true,
      })

      vim.cmd([[ colorscheme neofusion ]])
      vim.opt.pumblend = 0
      vim.opt.winblend = 0
      vim.api.nvim_set_hl(0, "PopMenu", { bg = "none", blend = 0 }) --Remove transparency and set background of completion popup
    end,
  },

  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("cyberdream").setup({
        -- Recommended - see "Configuring" below for more config options
        transparent = true,
        italic_comments = true,
        hide_fillchars = true,
        borderless_telescope = true,
        terminal_colors = true,
      })
      vim.cmd("colorscheme cyberdream") -- set the colorscheme
      vim.opt.pumblend = 0
      vim.opt.winblend = 0
      vim.api.nvim_set_hl(0, "PopMenu", { bg = "none", blend = 0 }) --Remove transparency and set background of completion popup
    end,
  },

  -- {
  --   "folke/tokyonight.nvim",
  --   require("notify").setup({
  --     background_colour = "#000000",
  --   }),
  --   opts = {
  --     transparent = true,
  --     styles = {
  --       sidebars = "transparent",
  --       floats = "transparent",
  --     },
  --   },
  -- },
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      on_highlights = function(hl, c)
        hl.DapBreakpoint = {
          fg = c.red,
          bg = c.bg,
        }
        hl.DapLogPoint = {
          fg = c.cyan,
          bg = c.bg,
        }
        hl.DapStopped = {
          fg = c.yellow,
          bg = c.bg,
        }
        hl.NormalFloat.bg = c.bg -- All floating buffers background like the lsp, autocomplete and such
        hl.WhichKeyFloat.bg = c.bg -- Whichkey popup background
        hl.FloatBorder.bg = c.bg -- Most floating borders except telescope
        hl.TelescopeBorder.bg = c.bg
        hl.TelescopeNormal.bg = c.bg
        hl.NeoTreeNormal.bg = c.bg --Neotree background
        hl.LspInfoBorder.bg = c.bg --Border for the LSPInfo window, leader + c + l
        vim.opt.pumblend = 0
        vim.opt.winblend = 0
        vim.api.nvim_set_hl(0, "PopMenu", { bg = "none", blend = 0 }) --Remove transparency and set background of completion popup
      end,
    },
  },
  {
    "catppuccin/catppuccin",
    enabled = false,
  },
  {
    "rebelot/kanagawa.nvim",
    enabled = true,
    opts = {
      -- transparent = true,
      theme = "wave",
      background = {
        dark = "wave",
        light = "lotus",
      },
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },
      overrides = function(colors)
        -- local theme = colors.theme
        -- Only setup the only ones needed
        vim.api.nvim_set_hl(0, "PopMenu", { bg = "none", blend = 0 })
        vim.opt.pumblend = 0
        vim.opt.winblend = 0
        return {
          NormalFloat = { bg = "none" }, -- All floating buffers background like the lsp, autocomplete and such
          FloatBorder = { bg = "none" }, -- Most floating borders except telescope
          TelescopeBorder = { bg = "none" },
        }
      end,
    },
  },

  {
    "craftzdog/solarized-osaka.nvim",
    lazy = true,
    priority = 1000,
    opts = function()
      return {
        transparent = true,
      }
    end,
  },

  {
    "xiyaowong/transparent.nvim",
  },
}
