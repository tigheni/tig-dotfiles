return {
  "johmsalas/text-case.nvim",
  config = function()
    local text_case = require("textcase")
    text_case.setup()

    vim.keymap.set("n", "gat", function()
      text_case.current_word("to_title_case")
    end, { desc = "Convert to Title Case" })
    vim.keymap.set("n", "gaT", function()
      text_case.current_word("to_title_case")
    end, { desc = "LSP rename to Title Case" })
    vim.keymap.set("n", "gaot", function()
      text_case.operator("to_title_case")
    end, { desc = "To Title Case" })
    vim.keymap.set("x", "gat", function()
      text_case.operator("to_title_case")
    end, { desc = "Convert to Title Case" })
  end,
}
