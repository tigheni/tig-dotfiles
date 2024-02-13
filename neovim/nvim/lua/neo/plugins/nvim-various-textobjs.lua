return {
  "chrisgrieser/nvim-various-textobjs",
  -- opts = { useDefaultKeymaps = true },
  config = function()
    local textobjs = require("various-textobjs")

    vim.keymap.set({ "o", "x" }, "am", '<cmd>lua require("various-textobjs").subword("outer")<CR>')
    vim.keymap.set({ "o", "x" }, "im", '<cmd>lua require("various-textobjs").subword("inner")<CR>')

    vim.keymap.set({ "o", "x" }, "ag", '<cmd>lua require("various-textobjs").entireBuffer()<CR>')
  end,
}
