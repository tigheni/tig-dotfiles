return {
  "ckolkey/ts-node-action",
  dependencies = { "nvim-treesitter" },
  config = function()
    vim.keymap.set({ "n" }, "<leader>o", require("ts-node-action").node_action, { desc = "Trigger Node Action" })
  end,
}
