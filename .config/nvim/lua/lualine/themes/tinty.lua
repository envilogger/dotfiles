-- lualine theme from the tinty palette (set by colors/tinty.lua)
local p = vim.g.tinty_palette
if not p then
  return require("lualine.themes.auto")
end

local function mode(color)
  return {
    a = { fg = p.base00, bg = color, gui = "bold" },
    b = { fg = p.base05, bg = p.base02 },
    -- Editor background, so the rounded ends of a and z stand out
    c = { fg = p.base04, bg = p.base00 },
  }
end

return {
  normal = mode(p.base0D),
  insert = mode(p.base0B),
  visual = mode(p.base0E),
  replace = mode(p.base08),
  command = mode(p.base0A),
  terminal = mode(p.base0C),
  inactive = {
    a = { fg = p.base03, bg = p.base01 },
    b = { fg = p.base03, bg = p.base01 },
    c = { fg = p.base03, bg = p.base01 },
  },
}
