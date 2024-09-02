return {
  "chrisgrieser/nvim-various-textobjs",
  -- opts = { useDefaultKeymaps = true },
  config = function()
    local textobjs = require("various-textobjs")

    vim.keymap.set({ "o", "x" }, "im", function()
      textobjs.subword("inner")
    end)
    vim.keymap.set({ "o", "x" }, "am", function()
      textobjs.subword("outer")
    end)

    -- vim.keymap.set({ "o", "x" }, "iq", function()
    --   textobjs.anyQuote("inner")
    -- end)
    -- vim.keymap.set({ "o", "x" }, "aq", function()
    --   textobjs.anyQuote("outer")
    -- end)

    -- vim.keymap.set({ "o", "x" }, "ib", function()
    --   textobjs.anyBracket("inner")
    -- end)
    -- vim.keymap.set({ "o", "x" }, "ab", function()
    --   textobjs.anyBracket("outer")
    -- end)

    vim.keymap.set({ "o", "x" }, "ih", function()
      textobjs.chainMember("inner")
    end)
    vim.keymap.set({ "o", "x" }, "ah", function()
      textobjs.chainMember("outer")
    end)

    vim.keymap.set({ "o", "x" }, "ag", textobjs.entireBuffer)

    vim.keymap.set({ "o", "x" }, "C", textobjs.toNextClosingBracket)
    vim.keymap.set({ "o", "x" }, "Q", textobjs.toNextQuotationMark)
  end,
}
