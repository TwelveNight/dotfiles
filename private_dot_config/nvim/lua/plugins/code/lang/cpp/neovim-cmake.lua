-- CMake integration for Neovim
return {
  {
    "Shatur/neovim-cmake",
    cmd = "CMake",
    keys = {
      { "<leader>mc", "<cmd>CMake configure<cr>", desc = "Configure project)" },
      { "<leader>mb", "<cmd>CMake build<cr>", desc = "Build current rule " },
      { "<leader>ma", "<cmd>CMake build_all<cr>", desc = "Build all rules " },
      { "<leader>mr", "<cmd>CMake run<cr>", desc = "Run selected target" },
      { "<leader>md", "<cmd>CMake debug<cr>", desc = "Run debugging on selected target" },
      { "<leader>mm", "<cmd>CMake clean<cr>", desc = "Execute clear target" },
      { "<leader>mp", "<cmd>CMake create_project<cr>", desc = "Create new CMake project" },
      { "<leader>mh", "<cmd>CMake clear_cache<cr>", desc = "Remove CMakeCache.txt file" },
      { "<leader>mo", "<cmd>CMake open_build_dir<cr>", desc = "Open current build folder" },
      {
        "<leader>ma",
        "<cmd>CMake set_target_arguments<cr>",
        desc = "Set arguments for running/debugging target",
      },
      { "<leader>msb", "<cmd>CMake select_build_type<cr>", desc = "Select build type" },
      { "<leader>msd", "<cmd>CMake select_dap_config<cr>", desc = "Select DAP configuration" },
      { "<leader>mst", "<cmd>CMake select_target<cr>", desc = "Select target for running/debugging" },
    },
  },
}
