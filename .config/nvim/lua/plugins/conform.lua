return {
  {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    opts = {
      -- log_level = vim.log.levels.TRACE,
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        json = { "prettierd", "prettier" },
        rust = { "rustfmt", lsp_format = "fallback" },
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
