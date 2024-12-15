return {
  "gopls",
  {
    on_attach = function()
      vim.keymap.set("n", "<leader>ao", function()
        vim.lsp.buf.code_action({
          apply = true,
          context = {
            only = { "source.organizeImports" },
            diagnostics = {},
          },
        })
      end, { desc = "Organize imports" })
    end,
  },
}
