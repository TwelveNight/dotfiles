return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
      table.insert(opts.sources, { name = "natdat" })
      table.insert(opts.sources, { name = "dictionary", keyword_length = 2 })

      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      -- vim.api.nvim_set_hl(0, "PopMenu", { bg = "#1F2335", blend = 0 })
      local win_opt = {
        border = "single",
        col_offset = 0,
        side_padding = 1,
        winhighlight = "Normal:PopMenu,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
      }

      local doc_opt = {
        col_offset = 0,
        side_padding = 1,
        winhighlight = "Normal:PopMenu,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
      }

      opts.view = {
        entries = {
          follow_cursor = true,
        },
      }

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            -- You could replace select_next_item() with confirm({ select = true }) to get VS Code autocompletion behavior
            cmp.confirm({ select = true })
          -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
          -- this way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
      })

      -- disable autoselection of the first option
      opts.preselect = cmp.PreselectMode.None
      opts.completion = {
        completeopt = "menu,menuone,noinsert,noselect",
      }

      opts.window = {
        completion = cmp.config.window.bordered(win_opt),
        documentation = cmp.config.window.bordered(doc_opt),
      }

      opts.experimental = {
        ghost_text = true,
      }
    end,
  },
  -- disable the return type in the LSP completion
  {
    "nvim-cmp",
    opts = function(_, opts)
      opts.formatting.format = function(_, item)
        local icons = require("lazyvim.config").icons.kinds
        if icons[item.kind] then
          item.kind = icons[item.kind] .. item.kind
        end
        item.menu = nil
        return item
      end
    end,
  },
}
