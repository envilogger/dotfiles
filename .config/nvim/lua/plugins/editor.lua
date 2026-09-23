return {
  -- leap instead of flash
  { "folke/flash.nvim", enabled = false },
  {
    url = "https://codeberg.org/andyg/leap.nvim",
    keys = {
      { "s", "<Plug>(leap)", mode = { "n", "x", "o" }, desc = "Leap" },
      { "S", "<Plug>(leap-from-window)", desc = "Leap from Window" },
    },
    opts = {},
  },

  -- harpoon: keep the old keys alongside the extra's <leader>h / <leader>H / <leader>1-9
  {
    "ThePrimeagen/harpoon",
    keys = {
      {
        "<C-e>",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Toggle Harpoon Menu",
      },
      { "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon Add File" },
    },
  },

  -- <leader>u is LazyVim's UI toggle group, so undotree lives on <leader>U
  {
    "jiaoshijie/undotree",
    opts = {},
    keys = {
      { "<leader>U", function() require("undotree").toggle() end, desc = "Undotree" },
    },
  },

  { "tpope/vim-fugitive", cmd = { "Git", "G", "Gdiffsplit", "Gread", "Gwrite", "Gvdiffsplit" } },

  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        sections = {
          { section = "header" },
          { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
          { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
          { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
      explorer = { replace_netrw = true },
      picker = {
        sources = {
          explorer = {
            layout = { preset = "vscode" },
            auto_close = true,
          },
        },
      },
    },
  },
}
