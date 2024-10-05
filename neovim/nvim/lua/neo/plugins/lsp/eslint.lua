local map_action = require("neo.plugins.lsp.utils").map_action

return {
  "eslint",
  {
    on_attach = function()
      map_action("<leader>at", { "for this line" }, "Disable ESLint rule for this line")
    end,
  },
}
