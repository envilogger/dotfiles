return {
  { "github/copilot.vim", event = "VeryLazy" },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    cmd = "CopilotChat",
    build = "make tiktoken",
    opts = {
      -- See Configuration section for options
      window = {
        -- layout = "float",
        -- width = 80, -- Fixed width in columns
        -- height = 20, -- Fixed height in rows
        -- border = "rounded", -- 'single', 'double', 'rounded', 'solid'
        title = "🤖 AI Assistant",
        zindex = 100, -- Ensure window stays on top
      },

      headers = {
        user = "👤 You",
        assistant = "🤖 Copilot",
        tool = "🔧 Tool",
      },

      separator = "━━",
      auto_fold = true, -- Automatically folds non-assistant messages
    },
  },
  -- {
  --   "ravitemer/mcphub.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --   },
  --   build = "npm install -g mcp-hub@latest", -- Installs `mcp-hub` node binary globally
  --   config = function()
  --     require("mcphub").setup()
  --   end,
  -- },
}
