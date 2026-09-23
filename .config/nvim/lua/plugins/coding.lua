return {
  -- completion
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "default",
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "select_and_accept", "fallback" },
      },
      appearance = {
        nerd_font_variant = "normal",
      },
      completion = {
        keyword = { range = "full" },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
        },
        ghost_text = { enabled = false },
      },
      sources = {
        providers = {
          cmdline = { min_keyword_length = 2 },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },

  -- nvim-autopairs instead of mini.pairs
  { "nvim-mini/mini.pairs", enabled = false },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- formatting (format-on-save is handled by LazyVim, toggle with <leader>uf)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        xml = { "xmlformatter" },
      },
      formatters = {
        xmlformatter = {
          inherit = true,
          prepend_args = { "--selfclose" },
        },
      },
    },
  },
}
