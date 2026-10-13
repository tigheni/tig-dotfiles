local map_action = require("neo.plugins.lsp.utils").map_action

return {
  "eslint",
  keymaps = function(bufnr)
    map_action(bufnr, "<leader>as", { "for this line" }, "Disable ESLint rule for this line")
  end,
}
