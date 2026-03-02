return {
  -- {
  --   "mason-org/mason.nvim",
  --   lazy = false,
  --
  --   opts = {
  --     registries = {
  --       "github:mason-org/mason-registry",
  --       "github:Crashdummyy/mason-registry",
  --     },
  --     ensure_installed = {
  --       "lua_ls",
  --       "rust_analyzer",
  --
  --       "xmlformatter",
  --       "csharpier",
  --
  --       "prettierd",
  --       "stylua",
  --
  --       "roslyn",
  --       "rzls",
  --     },
  --   },
  -- },
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts_extend = { "ensure_installed" },
        opts = {
          registries = {
            "github:mason-org/mason-registry",
            "github:Crashdummyy/mason-registry",
          },
          ensure_installed = {
            "lua_ls",
            "rust_analyzer",

            "xmlformatter",
            -- "csharpier",

            "prettierd",
            "stylua",

            "roslyn",
          },
        },
      },
      "neovim/nvim-lspconfig",
    },
  },
  {
    "seblyng/roslyn.nvim",
    -- event = "VeryLazy",
    ft = { "cs", "razor" },
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
