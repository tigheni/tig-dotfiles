return {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        panel = { enabled = false },
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = "<M-l>",
            accept_word = "<M-h>",
            accept_line = "<M-,>",
          },
        },
        filetypes = {
          markdown = true,
        },
      })
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    build = "make tiktoken",
    config = function()
      local chat = require("CopilotChat")

      vim.keymap.set({ "n", "x" }, "<leader>ac", chat.open, { desc = "AI: Chat" })
    end,
  },
}
