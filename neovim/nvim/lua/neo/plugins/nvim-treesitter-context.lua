return {
  "nvim-treesitter/nvim-treesitter-context",
  event = "BufReadPre",
  config = function()
    local tc = require("treesitter-context")
    tc.setup()
    vim.keymap.set("n", "<leader>t", "<cmd>TSContextToggle<CR>", { desc = "Toggle TS Context" })
    vim.keymap.set("n", "<leader>z", function()
      tc.go_to_context(1)
    end, { silent = true, desc = "Jump to context" })
    vim.keymap.set("n", "<leader>Z", function()
      tc.go_to_context(10)
    end, { silent = true, desc = "Jump to context (furthest)" })
  end,
}
