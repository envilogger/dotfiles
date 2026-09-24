return {
  {
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry", -- provides roslyn
      },
      ensure_installed = { "xmlformatter", "prettierd", "stylua", "roslyn" },
    },
  },

  -- keymaps from the previous config
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "gi", vim.lsp.buf.implementation, desc = "Goto Implementation" },
            { "gr", function() Snacks.picker.lsp_references() end, desc = "References", nowait = true },
            { "<leader>cR", vim.lsp.buf.rename, desc = "Rename Symbol", has = "rename" },
          },
        },
      },
    },
  },

  -- C#
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "c_sharp" } } },
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    opts = {},
    init = function()
      vim.lsp.config("roslyn", {
        settings = {
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
          },
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
          },
        },
      })
    end,
  },
}
