return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    event = "BufEnter",
    build = ":TSUpdate",
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
    opts = {
      indent = { enabled = true },
      highlight = { enabled = true, additional_vim_regex_highlighting = false },
      folds = { enabled = true },
      incremental_selection = { enabled = true },
      ensure_installed = {
        "c",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "rust",
        "javascript",
        "typescript",
        "yaml",
      },
      sync_install = false,
      auto_install = true,
      additional_vim_regex_highlighting = false,
    },
  },
}
