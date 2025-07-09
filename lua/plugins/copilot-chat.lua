return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim", enabled = false }, -- or zbirenbaum/copilot.lua
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    -- See Commands section for default commands if you want to lazy load on them
    config = function()
      require("CopilotChat").setup {
        sticky = {
          "#buffer:visible",
        },
      }
      local wk = require "which-key"
      local chat_icon = " " -- optional icon for styling

      wk.add {
        { "<leader>z", group = chat_icon .. "CopilotChat" },
        { "<leader>zc", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Chat" },
        { "<leader>zf", "<cmd>CopilotChatFix<cr>", desc = "Fix Code" },
        { "<leader>ze", "<cmd>CopilotChatExplain<cr>", desc = "Explain Code" },
        { "<leader>zr", "<cmd>CopilotChatReview<cr>", desc = "Review Code" },
        { "<leader>za", "<cmd>CopilotChatAgents<cr>", desc = "List Agents" },
        { "<leader>zs", "<cmd>CopilotChatReset<cr>", desc = "Reset Chat" },
        { "<leader>z", mode = "v", group = chat_icon .. "CopilotChat" },
        { "<leader>ze", ":CopilotChatExplain<cr>", mode = "v", desc = "Explain Selection" },
        { "<leader>zf", ":CopilotChatFix<cr>", mode = "v", desc = "Fix Selection" },
        { "<leader>zr", ":CopilotChatReview<cr>", mode = "v", desc = "Review Selection" },
      }
    end,
  },
}
