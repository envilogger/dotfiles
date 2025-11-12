return {
  {
    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      ---@type snacks.Config
      opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
        bigfile = {
          enabled = true,
        },
        dashboard = {
          enabled = true,
          sections = {
            { section = "header" },
            { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
            { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
            { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
            { section = "startup" },
          },
        },

        ---@class snacks.explorer.Config
        explorer = {
          enabled = true,
          replace_netrw = true,
        },

        indent = {
          enabled = true,
        },

        input = { enabled = true },
        picker = {
          enabled = true,
          sources = {
            explorer = {
              layout = {
                preset = "vscode"
              },
              auto_close = true,
            }
          }
        },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
      },
      init = function(_) end,
    },
  },
}
