return {
  {
    "jiaoshijie/undotree",
    event = "VeryLazy",
    ---@module 'undotree.collector'
    ---@type UndoTreeCollector.Opts
    opts = { },
    keys = { -- load the plugin only when using it's keybinding:
      { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
    },
  }
}
