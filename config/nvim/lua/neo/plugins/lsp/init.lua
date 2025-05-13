vim.lsp.inlay_hint.enable(true)
vim.diagnostic.config({
  virtual_text = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = "󰠠 ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },
})

vim.keymap.set("n", "<leader>i", "<cmd>LspInfo<CR>", { desc = "Restart LSP" })
vim.keymap.set("n", "<leader>c", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
vim.keymap.set("n", "<leader>aq", function()
  vim.lsp.buf.code_action({
    context = { only = { "quickfix" } }, ---@diagnostic disable-line: assign-type-mismatch,missing-fields
    apply = true,
  })
end, { desc = "Apply quickfix" })

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "saghen/blink.cmp",
    "b0o/schemastore.nvim",
  },
  config = function()
    local schema_store = require("schemastore")
    local language_servers = {
      "html",
      "cssls",
      require("neo.plugins.lsp.eslint"),
      "emmet_language_server",
      require("neo.plugins.lsp.vtsls"),
      "nixd",
      "hyprls",
      "pyright",
      require("neo.plugins.lsp.gopls"),
      {
        "tailwindcss",
        {
          settings = {
            tailwindCSS = {
              classAttributes = { "class", "className", "classNames" },
              experimental = {
                classRegex = {
                  { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                  { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                },
              },
            },
          },
        },
      },
      {
        "lua_ls",
        {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                library = {
                  [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                  [vim.fn.stdpath("config") .. "/lua"] = true,
                },
              },
            },
          },
        },
      },
      {
        "jsonls",
        {
          settings = {
            json = {
              schemas = schema_store.json.schemas(),
              validate = true,
            },
          },
        },
      },
      {
        "yamlls",
        {
          settings = {
            yaml = {
              schemaStore = {
                enable = false,
                url = "",
              },
              schemas = schema_store.yaml.schemas(),
            },
          },
        },
      },
      { "typos_lsp", { init_options = { diagnosticSeverity = "Info" }, filetypes = { "*" } } },
    }

    local lspconfig = require("lspconfig")
    local capabilities = require("blink.cmp").get_lsp_capabilities()

    for _, lsp in ipairs(language_servers) do
      if type(lsp) == "table" then
        lspconfig[lsp[1]].setup(vim.tbl_extend("force", lsp[2], { capabilities = capabilities }))
      else
        lspconfig[lsp].setup({ capabilities = capabilities })
      end
    end
  end,
}
