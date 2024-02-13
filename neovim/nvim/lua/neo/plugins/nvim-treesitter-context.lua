return {
  "nvim-treesitter/nvim-treesitter-context",
  event = "BufReadPre",
  config = function()
    local tc = require("treesitter-context")
    tc.setup()
    vim.keymap.set("n", "<leader>t", "<cmd>TSContextToggle<CR>", { desc = "Toggle TS Context" })
    vim.keymap.set("n", "<leader>z", function()
      tc.go_to_context(vim.v.count1)
    end, { silent = true, desc = "Jump to context (upwards)" })
  end,
}
