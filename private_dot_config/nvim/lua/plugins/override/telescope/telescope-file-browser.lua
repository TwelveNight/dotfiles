return {
  {
    "telescope.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      "nvim-telescope/telescope-file-browser.nvim",
    },
    keys = {
      {
        ";;",
        function()
          local builtin = require("telescope.builtin")
          builtin.resume()
        end,
        desc = "Resume the previous telescope picker",
      },
      { ";a", "<cmd>Telescope autocommands<cr>", desc = "Auto Commands" },
      { ";b", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Switch Buffer" },
      { ";c", "<cmd>Telescope command_history<cr>", desc = "Command History" },
      { ";C", "<cmd>Telescope commands<cr>", desc = "Commands" },
      {
        ";d",
        function()
          local builtin = require("telescope.builtin")
          builtin.diagnostics()
        end,
        desc = "Lists Diagnostics for all open buffers or a specific buffer",
      },
      { ";D", "<cmd>Telescope diagnostics<cr>", desc = "Workspace Diagnostics" },
      -- { ";f", LazyVim.telescope("files"), desc = "Find Files (Root Dir)" },
      -- { ";F", LazyVim.telescope("files", { cwd = false }), desc = "Find Files (cwd)" },
      -- { ";g", LazyVim.telescope("live_grep"), desc = "Grep (Root Dir)" },
      -- { ";G", LazyVim.telescope("live_grep", { cwd = false }), desc = "Grep (cwd)" },
      { ";h", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
      { ";k", "<cmd>Telescope keymaps<cr>", desc = "Key Maps" },
      { ";M", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
      { ";m", "<cmd>Telescope marks<cr>", desc = "Jump to Mark" },
      {
        ";p",
        function()
          require("telescope.builtin").find_files({
            cwd = require("lazy.core.config").options.root,
          })
        end,
        desc = "Find Plugin File",
      },
      { ";r", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
      {
        ";s",
        function()
          require("telescope.builtin").lsp_document_symbols({
            symbols = require("lazyvim.config").get_kind_filter(),
          })
        end,
        desc = "Goto Symbol",
      },
      {
        ";S",
        function()
          require("telescope.builtin").lsp_dynamic_workspace_symbols({
            symbols = require("lazyvim.config").get_kind_filter(),
          })
        end,
        desc = "Goto Symbol (Workspace)",
      },
      -- { ";u", LazyVim.telescope("colorscheme", { enable_preview = true }), desc = "Colorscheme with Preview" },
      -- { ";w", LazyVim.telescope("grep_string", { word_match = "-w" }), desc = "Word (Root Dir)" },
      -- { ";W", LazyVim.telescope("grep_string", { cwd = false, word_match = "-w" }), desc = "Word (cwd)" },
      -- { ";w", LazyVim.telescope("grep_string"), mode = "v", desc = "Selection (Root Dir)" },
      -- { ";W", LazyVim.telescope("grep_string", { cwd = false }), mode = "v", desc = "Selection (cwd)" },
      -- {
      --   ";o",
      --   function()
      --     local telescope = require("telescope")
      --
      --     local function telescope_buffer_dir()
      --       return vim.fn.expand("%:p:h")
      --     end
      --
      --     telescope.extensions.file_browser.file_browser({
      --       path = "%:p:h",
      --       cwd = telescope_buffer_dir(),
      --       respect_gitignore = false,
      --       hidden = true,
      --       grouped = true,
      --       previewer = false,
      --       initial_mode = "normal",
      --       layout_config = { height = 40 },
      --     })
      --   end,
      --   desc = "Open File Browser with the path of the current buffer",
      -- },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local fb_actions = require("telescope").extensions.file_browser.actions

      opts.defaults = vim.tbl_deep_extend("force", opts.defaults, {
        wrap_results = true,
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          n = {},
        },
      })
      opts.pickers = {
        diagnostics = {
          theme = "ivy",
          initial_mode = "normal",
          layout_config = {
            preview_cutoff = 9999,
          },
        },
      }
      opts.extensions = {
        file_browser = {
          theme = "dropdown",
          -- disables netrw and use telescope-file-browser in its place
          hijack_netrw = true,
          mappings = {
            -- your custom insert mode mappings
            ["n"] = {
              -- your custom normal mode mappings
              ["N"] = fb_actions.create,
              ["h"] = fb_actions.goto_parent_dir,
              ["/"] = function()
                vim.cmd("startinsert")
              end,
              ["<C-u>"] = function(prompt_bufnr)
                for i = 1, 10 do
                  actions.move_selection_previous(prompt_bufnr)
                end
              end,
              ["<C-d>"] = function(prompt_bufnr)
                for i = 1, 10 do
                  actions.move_selection_next(prompt_bufnr)
                end
              end,
              ["<PageUp>"] = actions.preview_scrolling_up,
              ["<PageDown>"] = actions.preview_scrolling_down,
            },
          },
        },
      }
      telescope.setup(opts)
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("file_browser")
    end,
  },

  {
    "jvgrootveld/telescope-zoxide", -- <c-b> does not work
    keys = {
      {
        ";z",
        function()
          require("telescope").extensions.zoxide.list()
        end,
        desc = "Zoxide file navigation",
      },
    },
    config = function()
      require("telescope").load_extension("zoxide")
    end,
  },
}
