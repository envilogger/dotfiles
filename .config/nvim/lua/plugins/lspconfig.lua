return {
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    opts = {
      ensure_installed = { "lua_ls" },
    },
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts_extend = { "ensure_installed" },
        opts = {
          ensure_installed = {
            "prettierd",
            "stylua",
            "rust_analyzer",
          },
        },
      },
      "neovim/nvim-lspconfig",
    },
  },
  {
    "seblyng/roslyn.nvim",
    event = "VeryLazy",
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      -- your configuration comes here; leave empty for default settings
      settings = {
        ["csharp|inlay_hints"] = {
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
        },
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
        },
      },
    },
  },
}
