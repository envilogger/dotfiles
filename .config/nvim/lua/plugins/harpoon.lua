return {
  {
    "theprimeagen/harpoon",
    branch = "harpoon2",
    keys = {
      {
        "<C-e>",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Toggle Harpoon Menu",
      },
      {
        "<leader>a",
        function()
          local harpoon = require("harpoon")
          harpoon:list():add()
        end,
      },
    },
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    init = function()
      local harpoon = require("harpoon")
      vim.keymap.set("n", "<leader>a", function()
        harpoon:list():add()
      end)
    end,
  },
}
