-- Bubble-style statusline from the previous config
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.theme = "tinty"
      opts.options.component_separators = ""
      opts.options.section_separators = { left = "", right = "" }
      opts.sections = {
        lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
        lualine_b = { "filename", "branch", "diagnostics" },
        lualine_c = { "%=" },
        lualine_x = {},
        lualine_y = { "lsp_status", "filetype", "progress" },
        lualine_z = {
          { "location", separator = { right = "" }, left_padding = 2 },
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
