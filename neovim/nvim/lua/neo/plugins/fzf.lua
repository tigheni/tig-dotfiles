return {
  "ibhagwan/fzf-lua",
  enabled = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local fzf = require("fzf-lua")

    -- vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "Word under cursor" })
    -- vim.keymap.set("n", "<leader>sg", function()
    --   builtin.live_grep({ additional_args = { "--smart-case" } })
    -- end, { desc = "Telescope: Grep (smart case)" })
    -- vim.keymap.set("n", "<leader>sG", builtin.live_grep, { desc = "Telescope: Grep (case sensitive)" })
    -- vim.keymap.set("n", "<leader><space>", fzf.files, { desc = "Telescope: Git Files" })
    -- vim.keymap.set("n", "<leader>ss", builtin.lsp_document_symbols, { desc = "Telescope: Document Symbols" })
    -- vim.keymap.set("n", "<leader>sb", builtin.current_buffer_fuzzy_find, { desc = "Telescope: Search Buffer" })
    -- vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "Telescope: Resume" })
    -- vim.keymap.set("n", "<leader>r", builtin.oldfiles, { desc = "Telescope: Recent Files" })
    -- vim.keymap.set("n", "<leader>o", builtin.buffers, { desc = "Telescope: Buffers" })
    -- vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Telescope: Key Maps" })
    -- vim.keymap.set("n", "<leader>sc", builtin.commands, { desc = "Telescope: Commands" })
    -- vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "Show LSP references" })
    -- vim.keymap.set("n", "<leader>sd", function()
    --   builtin.diagnostics({ bufnr = 0 })
    -- end, { desc = "Show buffer diagnostics" })
    -- vim.keymap.set("n", "<leader>sD", builtin.diagnostics, { desc = "Show workspace diagnostics" })
  end,
}
