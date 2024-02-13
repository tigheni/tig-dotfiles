return {
  "yioneko/nvim-vtsls",
  config = function()
    require("lspconfig.configs").vtsls = require("vtsls").lspconfig -- set default server config, optional but recommended

    vim.keymap.set("n", "<leader>ai", "<cmd>VtsExec add_missing_imports<CR>", { desc = "Add missing imports" })
    vim.keymap.set("n", "<leader>ar", "<cmd>VtsExec remove_unused<CR>", { desc = "Remove unused variables" })
    vim.keymap.set("n", "<leader>ao", "<cmd>VtsExec organize_imports<CR>", { desc = "Organize imports" })
  end,
}
