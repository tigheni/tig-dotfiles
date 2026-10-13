vim.lsp.inlay_hint.enable(true)
vim.diagnostic.config({
  virtual_text = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = "󰠠 ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },
})

vim.keymap.set("n", "<leader>i", "<cmd>checkhealth vim.lsp<CR>", { desc = "LSP info" })
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
    -- Each entry is a server name, or { name, config?, keymaps = function(bufnr) }.
    -- config is merged into nvim-lspconfig's defaults via vim.lsp.config.
    local language_servers = {
      "html",
      "cssls",
      require("neo.plugins.lsp.eslint"),
      "emmet_language_server",
      require("neo.plugins.lsp.vtsls"),
      require("neo.plugins.lsp.nixd"),
      "hyprls",
      "pyright",
      "ruff",
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
      -- no filetypes: attaches to every buffer
      { "typos_lsp", { init_options = { diagnosticSeverity = "Info" } } },
    }

    vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

    local keymaps = {}
    for _, lsp in ipairs(language_servers) do
      if type(lsp) == "string" then
        lsp = { lsp }
      end
      local name = lsp[1]
      if lsp[2] then
        vim.lsp.config(name, lsp[2])
      end
      keymaps[name] = lsp.keymaps
      vim.lsp.enable(name)
    end

    -- Server keymaps go through LspAttach instead of on_attach so they stay
    -- buffer-local and don't replace nvim-lspconfig's own on_attach handlers.
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp_server_keymaps", { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        local set_keymaps = client and keymaps[client.name]
        if set_keymaps then
          set_keymaps(event.buf)
        end
      end,
    })
  end,
}
