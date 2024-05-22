local code_actions = require("neo.utils.code-actions")

local function map_action(keymap, action, desc)
  desc = desc or action[1]
  vim.keymap.set({ "n", "v" }, keymap, function()
    code_actions.apply(action)
  end, { desc = desc })
end

local on_attach = function(_, bufnr)
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Jump to definition" })
  vim.keymap.set("n", "gr", function()
    vim.lsp.buf.references({ includeDeclaration = false })
  end, { buffer = bufnr, desc = "Show LSP references" })
  vim.keymap.set("n", "<leader>n", vim.lsp.buf.rename, { buffer = bufnr, desc = "Smart rename" })
  vim.keymap.set({ "n", "x" }, "<leader>al", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Show code actions" })
  vim.keymap.set("n", "<leader>c", vim.diagnostic.open_float, { buffer = bufnr, desc = "Show line diagnostics" })
  vim.keymap.set("i", "<C-l>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Show signature help" })
  vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "Go to previous diagnostic" })
  vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { buffer = bufnr, desc = "Go to next diagnostic" })
  vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Show hover" })
  vim.keymap.set("n", "<leader>i", "<cmd>LspRestart<CR>", { buffer = bufnr, desc = "Restart LSP" })

  map_action(
    "<leader>aa",
    { "Remove braces from arrow function", "Add braces to arrow function" },
    "Toggle arrow function braces"
  )
  map_action("<leader>ak", { "Inline variable" })
  map_action("<leader>ae", { "Extract to constant in enclosing scope", "Extract to type alias" })
  map_action("<leader>af", { "Extract to function in module scope" })
  map_action("<leader>am", { "Convert to named function" })
end

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
      "nil_ls",
      -- "eslint",
      {
        "tailwindcss",
        {
          settings = {
            tailwindCSS = {
              classAttributes = { "class", "className", "classNames" },
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
      -- {
      --   "tsserver",
      --   {
      --     init_options = {
      --       preferences = {
      --         importModuleSpecifierPreference = "relative",
      --       },
      --     },
      --   },
      -- },
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
