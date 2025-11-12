vim.g.mapleader = " " -- set leader key to space
vim.o.laststatus = 3 -- global statusline

vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- if in vscode, load the vscode config and return
if vim.g.vscode then
  require("vsc")
  return
end

require("config.lazy")
require("config.lsp.lua")
require("config.lsp.dotnet")
require("config.lsp.rust")
require("remap")

-- General settings
-- hide command line unless needed
vim.opt.cmdheight = 0
-- show relative line numbers
vim.o.relativenumber = true
-- LSP-based folding
-- vim.o.foldmethod = "expr"
-- vim.o.foldexpr = "nvim_treesitter#foldexpr()"
-- vim.o.foldlevel = 99 -- start with all folds open

vim.o.shiftwidth = 2

-- folding
vim.o.foldenable = true
vim.o.foldlevelstart = 99 -- start with all folds open
vim.api.nvim_create_autocmd({ "FileType" }, {
  callback = function()
    -- check if treesitter has parser
    if require("nvim-treesitter.parsers").has_parser() then
      -- use treesitter folding
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    else
      -- use alternative foldmethod
      vim.opt.foldmethod = "syntax"
    end
  end,
})
