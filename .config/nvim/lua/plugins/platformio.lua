-- embedded development with PlatformIO (clangd itself comes from the lang.clangd extra)
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          root_markers = { "platformio.ini", "compile_commands.json", "compile_flags.txt", "Makefile", ".git" },
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            -- let clangd ask PlatformIO's cross compilers for their system includes and target
            "--query-driver=" .. vim.fn.expand("~/.platformio/packages/toolchain-*/bin/*"),
          },
        },
      },
    },
  },

  {
    "anurag3301/nvim-platformio.lua",
    main = "platformio",
    cmd = {
      "Pioinit",
      "PioLSP",
      "Piorun",
      "Piocmdh",
      "Piocmdf",
      "Piolib",
      "Piomon",
      "Piolsserial",
      "Piodebug",
      "PioTermList",
    },
    keys = {
      { "<leader>P", "", desc = "+platformio" },
      { "<leader>Pi", "<cmd>Pioinit<cr>", desc = "Init Project (pick board)" },
      { "<leader>Pb", "<cmd>Piorun build<cr>", desc = "Build" },
      { "<leader>Pu", "<cmd>Piorun upload<cr>", desc = "Upload" },
      { "<leader>Pc", "<cmd>Piorun clean<cr>", desc = "Clean" },
      { "<leader>Pm", "<cmd>Piomon<cr>", desc = "Serial Monitor" },
      { "<leader>Ps", "<cmd>Piolsserial<cr>", desc = "List Serial Ports" },
      { "<leader>Pl", "<cmd>Piolib<cr>", desc = "Search Libraries" },
      { "<leader>PL", "<cmd>PioLSP<cr>", desc = "Regenerate compile_commands.json" },
      { "<leader>Pd", "<cmd>Piodebug<cr>", desc = "Debug (pio debug)" },
      { "<leader>Pt", "<cmd>PioTermList<cr>", desc = "PIO Terminals" },
      { "<leader>Px", "<cmd>Piocmdf<cr>", desc = "Run pio Command" },
    },
    dependencies = {
      "akinsho/toggleterm.nvim",
      "nvim-lua/plenary.nvim",
      "folke/which-key.nvim",
      "nvim-treesitter/nvim-treesitter",
      "folke/snacks.nvim",
    },
    opts = {
      lsp = "clangd",
      clangd_source = "compiledb", -- `pio run -t compiledb`, no ccls needed
      picker_backend = "snacks",
    },
  },
  { "akinsho/toggleterm.nvim", lazy = true, opts = {} },

  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "c", "cpp", "ini" } } },
}
