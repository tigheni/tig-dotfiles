return {
  "gopls",
  keymaps = function(bufnr)
    vim.keymap.set("n", "<leader>ao", function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { "source.organizeImports" },
          diagnostics = {},
        },
      })
    end, { buffer = bufnr, desc = "Organize imports" })
  end,
}
