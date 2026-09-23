-- Colorscheme from tinty: builds highlights from $XDG_STATE_HOME/theme/palette.json,
-- which ~/.config/quickshell/tinty-hook.sh writes on `tinty apply`.
-- Running instances follow the file live (see the watcher below).

local state = (vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state")) .. "/theme"
local path = state .. "/palette.json"

local ok, data = pcall(function()
  return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
end)
local has_base16, base16 = pcall(require, "mini.base16")
if not (ok and has_base16) then
  vim.notify("tinty: can't load " .. (ok and "mini.base16" or path) .. ", using default colors", vim.log.levels.WARN)
  vim.cmd.colorscheme("default")
  return
end

vim.cmd("highlight clear")
vim.o.background = data.variant == "light" and "light" or "dark"

local palette = {}
for i = 0, 15 do
  local key = string.format("base%02X", i)
  palette[key] = data.palette[key]
end
base16.setup({ palette = palette })
vim.g.tinty_palette = palette -- read by lua/lualine/themes/tinty.lua
vim.g.colors_name = "tinty"

-- Re-apply when tinty replaces palette.json (atomically, via mv, so watch the directory).
if not vim.g.tinty_watching then
  vim.g.tinty_watching = true
  local watcher = assert(vim.uv.new_fs_event())
  local pending = false
  watcher:start(state, {}, function(err, filename)
    if err or filename ~= "palette.json" or pending then
      return
    end
    pending = true
    vim.defer_fn(function()
      pending = false
      if vim.g.colors_name == "tinty" then
        vim.cmd.colorscheme("tinty")
      end
    end, 100)
  end)
end
