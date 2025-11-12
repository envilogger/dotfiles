local snacks = require("snacks")

require("which-key").add({
  -- global
  { "<leader><leader>", snacks.picker.files, desc = "Find files" },
  { "<C-n>", function() snacks.explorer() end, desc = "Open explorer" },
  { "<Esc>", mode = "t", "<C-\\><C-n>", desc = "Exit terminal mode" },
  { "<C-.>", vim.lsp.buf.code_action, desc = "LSP Code action" },
  { "<C-/>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal", mode = { "n", "i", "t" } },
  { "<C-_>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal", mode = { "n", "i", "t" } },

  -- navigation between windows in normal mode
  { "<C-h>", "<C-w>h", desc = "Go to left window" },
  { "<C-j>", "<C-w>j", desc = "Go to lower window" },
  { "<C-k>", "<C-w>k", desc = "Go to upper window" },
  { "<C-l>", "<C-w>l", desc = "Go to right window" },

  -- navigation from terminal
  { "<C-h>", "<C-\\><C-n><C-w>h", mode = "t", desc = "Go to left window" },
  { "<C-j>", "<C-\\><C-n><C-w>j", mode = "t", desc = "Go to lower window" },
  { "<C-k>", "<C-\\><C-n><C-w>k", mode = "t", desc = "Go to upper window" },
  { "<C-l>", "<C-\\><C-n><C-w>l", mode = "t", desc = "Go to right window" },

  { "<leader>f", group = "File" },
  { "<leader>ff", snacks.picker.files, desc = "Find Files" },
  { "<leader>fg", snacks.picker.grep, desc = "Live Grep" },
  { "<leader>fb", snacks.picker.buffers, desc = "Buffers" },
  { "<leader>fh", snacks.picker.help, desc = "Help Tags" },

  { "<leader>g", group = "Git" },
  { "<leader>w", group = "Window" },

  { "<leader>a", group = "AI" },
  { "<leader>ac", "<cmd>CopilotChat<cr>", desc = "Open Chat" },

  -- buffers
  { "<leader>b", group = "Buffer" },
  { "<leader>bdc", snacks.bufdelete.delete, desc = "Close buffer" },
  { "<leader>bda", snacks.bufdelete.all, desc = "Close all buffers" },
  { "<leader>bdo", snacks.bufdelete.other, desc = "Close other buffers" },

  -- lsp / code
  { "<leader>c", group = "LSP / Code" },
  { "<leader>ca", vim.lsp.buf.code_action, desc = "Code action" },
  { "<leader>cR", vim.lsp.buf.rename, desc = "Rename Symbol" },
  { "gd", vim.lsp.buf.definition, desc = "Go to Definition" },
  { "gi", vim.lsp.buf.implementation, desc = "Go to Implementation" },
  { "gr", snacks.picker.lsp_references, desc = "List References" },

  -- format
  { "<leader>r", group = "Reformat" },
  { "<leader>rr", require("conform").format, desc = "Reformat Buffer" },
  { "<leader>rn", "<cmd>ConformInfo<cr>", desc = "Formatter Info" },

  -- project
  { "<leader>p", group = "Project" },
  { "<leader>pp", snacks.picker.projects, desc = "List recent projects" },

  -- no group
  { "<leader>nn", snacks.picker.notifications, desc = "Show notification history" },
})
