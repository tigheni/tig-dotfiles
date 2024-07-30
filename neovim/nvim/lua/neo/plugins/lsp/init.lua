local function map_action(keymap, actions, desc)
  desc = desc or actions[1]
  vim.keymap.set({ "n", "v" }, keymap, function()
    vim.lsp.buf.code_action({
      filter = function(action)
        for _, v in ipairs(actions) do
          if vim.startswith(action.title, v) then
            return true
          end
        end
        return false
      end,
      apply = true,
    })
  end, { desc = desc })
end

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

  map_action(
    "<leader>aa",
    { "Remove braces from arrow function", "Add braces to arrow function" },
    "Toggle arrow function braces"
  )
  map_action("<leader>ak", { "Inline variable" })
  map_action("<leader>ae", { "Extract to constant in enclosing scope", "Extract to type alias" })
  map_action("<leader>aE", { "Extract to constant in module scope" })
  map_action("<leader>af", { "Extract to function in module scope" })
  map_action("<leader>am", { "Convert to named function" })
  map_action("<leader>an", { "Move to a new file" })
  map_action("<leader>aN", { "Move to file" })
  map_action("<leader>ad", { "Convert named export to default export" })
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
      "emmet_language_server",
      require("neo.plugins.lsp.vtsls"),
      "nixd",
      "pyright",
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
      { "typos_lsp", { init_options = { diagnosticSeverity = "Info" } } },
    }

    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    for _, lsp in ipairs(language_servers) do
      if type(lsp) == "table" then
        lspconfig[lsp[1]].setup(vim.tbl_extend("force", lsp[2], { on_attach = on_attach, capabilities = capabilities }))
      else
        lspconfig[lsp].setup({ on_attach = on_attach, capabilities = capabilities })
      end
    end
  end,
}
