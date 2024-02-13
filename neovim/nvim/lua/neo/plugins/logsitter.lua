return {
  "gaelph/logsitter.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    local logsitter = require("logsitter")
    logsitter.setup({
      path_format = "fileonly",
    })
    vim.keymap.set("n", "<leader>m", logsitter.log, { desc = "Debugprint variable" })
    vim.keymap.set("n", "<leader>j", logsitter.clear_buf, { desc = "Delete all debugprints" })
  end,
}
