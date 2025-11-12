return {
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    init = function()
      vim.keymap.set("n", "<leader>gs", vim.cmd.Git);
    end
  }
}
