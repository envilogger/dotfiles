return {
  {
    "catppuccin/nvim",
    name = "catppucin",
    lazy = false,
    priority = 10000,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      background = {
        light = "latte",
        dark = "mocha",
      },
      transparent_background = true,
      float = {
        transparent = true,
        solid = true,
      },
      show_end_of_buffer = true,
      term_colors = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        neotree = true,
        telescope = {
          enabled = true,
        },
        treesitter = true,
        which_key = true,
        blink_cmp = {
          style = "bordered",
        },
        leap = true,
        harpoon = true,
        mason = true,
        notify = true,
        snacks = {
          enabled = true,
          indent_scope_color = "lavender", -- catppuccin color (eg. `lavender`) Default: text
        },
        copilot_vim = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
    end,

    init = function()
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
