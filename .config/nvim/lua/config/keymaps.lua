-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ported from the previous config
local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

map("n", "<C-n>", function() Snacks.explorer() end, { desc = "Open explorer" })
map("n", "<C-.>", vim.lsp.buf.code_action, { desc = "LSP Code action" })

-- <Esc> leaves terminal mode (except in lazygit, which needs <Esc> itself)
map("t", "<Esc>", function()
  return vim.api.nvim_buf_get_name(0):find("lazygit") and "<Esc>" or "<C-\\><C-n>"
end, { expr = true, desc = "Exit terminal mode" })

-- pickers
map("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "Live Grep" })
map("n", "<leader>fh", function() Snacks.picker.help() end, { desc = "Help Tags" })
map("n", "<leader>fp", function() Snacks.picker.resume() end, { desc = "Resume Picker" })
map("n", "<leader>pp", function() Snacks.picker.projects() end, { desc = "List recent projects" })

-- format
map("n", "<leader>rr", function() LazyVim.format({ force = true }) end, { desc = "Reformat Buffer" })
map("n", "<leader>rn", "<cmd>ConformInfo<cr>", { desc = "Formatter Info" })

-- git
map("n", "<leader>gs", vim.cmd.Git, { desc = "Git (fugitive)" })
