return {
  { "L3MON4D3/LuaSnip", keys = {} },
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "1.*",
    event = "VeryLazy",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "default",

        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "select_and_accept", "fallback" },
        -- Disable to avoid conflicts with copilot
        -- ["<Tab>"] = { "select_and_accept", "fallback" },
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
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          cmdline = {
            min_keyword_length = 2,
          },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
}
