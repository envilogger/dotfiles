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

  -- Ctrl+h/j/k/l across nvim splits and tmux panes (tmux side in tmux.conf)
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight" },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to Left Window/Pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to Lower Window/Pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to Upper Window/Pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to Right Window/Pane" },
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
      -- Don't generate a lazygit theme from nvim highlights: lazygit keeps the tinty
      -- theme from LG_CONFIG_FILE, like outside nvim (edit preset is in config.yml).
      lazygit = { configure = false },
      -- Editor background for the lazygit float, as in a standalone terminal
      styles = {
        lazygit = { wo = { winhighlight = "Normal:Normal,NormalNC:Normal" } },
      },
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
