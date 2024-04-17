return {
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
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa",
    },
  },
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

  {
    "hrsh7th/nvim-cmp",
    opts = function()
      vim.opt.pumblend = 0
      vim.opt.winblend = 0
    end,
  },
}
