-- Bubble-style statusline from the previous config
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.theme = "tinty"
      opts.options.component_separators = ""
      -- Nerd Font half circles: rounded ends like the Hyprland window corners
      opts.options.section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" }
      opts.sections = {
        lualine_a = { { "mode", separator = { left = "\u{e0b6}" }, right_padding = 2 } },
        lualine_b = { "filename", "branch", "diagnostics" },
        lualine_c = { "%=" },
        lualine_x = {},
        lualine_y = { "lsp_status", "filetype", "progress" },
        lualine_z = {
          { "location", separator = { right = "\u{e0b4}" }, left_padding = 2 },
        },
      }
      opts.inactive_sections = {
        lualine_a = { "filename" },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { "location" },
      }
    end,
  },
}
