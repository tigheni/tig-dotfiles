local function filter(arr, fn)
  if type(arr) ~= "table" then
    return arr
  end

  local filtered = {}
  for k, v in pairs(arr) do
    if fn(v, k, arr) then
      table.insert(filtered, v)
    end
  end

  return filtered
end

-- https://github.com/microsoft/TypeScript/pull/57969
local function definitionPredicate(value)
  return string.match(value.targetUri, "%.d.ts") == nil
end

local function referencePredicate(value)
  return not vim.startswith(value.text, "import")
    and not vim.startswith(vim.trim(value.text), "</")
    and not vim.startswith(value.text, "export default")
end

return {
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("typescript-tools").setup({
        settings = {
          separate_diagnostic_server = false,
          tsserver_file_preferences = {
            importModuleSpecifierPreference = "relative",
          },
        },
        handlers = {
          ["textDocument/definition"] = function(err, result, method, ...)
            if vim.tbl_islist(result) and #result > 1 then
              local filtered_result = filter(result, definitionPredicate)
              return vim.lsp.handlers["textDocument/definition"](err, filtered_result, method, ...)
            end

            vim.lsp.handlers["textDocument/definition"](err, result, method, ...)
          end,
          ["textDocument/references"] = function(_, result)
            local opts = {}
            require("telescope.pickers")
              .new(opts, {
                prompt_title = "LSP References",
                finder = require("telescope.finders").new_table({
                  results = filter(vim.lsp.util.locations_to_items(result), referencePredicate),
                  entry_maker = require("telescope.make_entry").gen_from_quickfix(opts),
                }),
                previewer = require("telescope.config").values.qflist_previewer(opts),
              })
              :find()
          end,
        },
      })
      vim.keymap.set("n", "<leader>ai", "<cmd>TSToolsAddMissingImports<CR>", { desc = "Add missing imports" })
      vim.keymap.set("n", "<leader>ar", "<cmd>TSToolsRemoveUnused<CR>", { desc = "Remove unused variables" })
      vim.keymap.set("n", "<leader>ao", "<cmd>TSToolsOrganizeImports<CR>", { desc = "Organize imports" })
    end,
  },
  {
    "dmmulroy/tsc.nvim",
    opts = {},
  },
}
