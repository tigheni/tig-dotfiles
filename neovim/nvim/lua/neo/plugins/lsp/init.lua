local on_attach = function(client, bufnr)
  if client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint.enable(true)
  end

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Jump to definition" })
  vim.keymap.set("n", "gr", function()
    vim.lsp.buf.references({ includeDeclaration = false })
  end, { buffer = bufnr, desc = "Show LSP references" })
  vim.keymap.set("n", "<leader>n", vim.lsp.buf.rename, { buffer = bufnr, desc = "Smart rename" })
  vim.keymap.set({ "n", "x" }, "<leader>al", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Show code actions" })
  vim.keymap.set("n", "<leader>c", vim.diagnostic.open_float, { buffer = bufnr, desc = "Show line diagnostics" })
  vim.keymap.set("i", "<C-l>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Show signature help" })

  vim.keymap.set("n", "<leader>aq", function()
    vim.lsp.buf.code_action({
      context = { only = { "quickfix" } }, ---@diagnostic disable-line: assign-type-mismatch,missing-fields
      apply = true,
    })
  end, { desc = "Apply quickfix" })
end

vim.keymap.set("n", "<leader>i", "<cmd>LspInfo<CR>", { desc = "Restart LSP" })

local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
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
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    for _, lsp in ipairs(language_servers) do
      if type(lsp) == "table" then
        lspconfig[lsp[1]].setup(vim.tbl_extend("force", lsp[2], {
          on_attach = function(client, bufnr)
            on_attach(client, bufnr)
            if lsp[2].on_attach then
              lsp[2].on_attach(client, bufnr)
            end
          end,
          capabilities = capabilities,
        }))
      else
        lspconfig[lsp].setup({ on_attach = on_attach, capabilities = capabilities })
      end
    end
  end,
}
