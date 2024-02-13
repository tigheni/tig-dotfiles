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
    and (
      value.originSelectionRange.start.line ~= value.targetRange.start.line
      or value.targetUri ~= vim.uri_from_bufnr(0)
    )
end

local function referencePredicate(value)
  return not vim.startswith(value.text, "import")
    and not vim.startswith(string.sub(value.text, value.col - 2, value.col - 1), "</")
    and not vim.startswith(value.text, "export")
end

return {
  "vtsls",
  {
    settings = {
      vtsls = {
        autoUseWorkspaceTsdk = true,
        enableMoveToFileCodeAction = true,
        experimental = {
          completion = {
            enableServerSideFuzzyMatch = true,
          },
        },
      },
      typescript = {
        suggest = {
          completeFunctionCalls = true,
        },
        preferences = {
          importModuleSpecifier = "non-relative",
          includePackageJsonAutoImports = false,
          autoImportFileExcludePatterns = { "@headlessui/react", "@radix-ui", "chart.js" },
          preferTypeOnlyAutoImports = true,
        },
        updateImportsOnFileMove = {
          enabled = "always",
        },
      },
    },
    handlers = {
      ["textDocument/definition"] = function(err, locations, method, ...)
        if vim.islist(locations) and #locations > 1 then
          locations = filter(locations, definitionPredicate)
        end

        vim.lsp.handlers["textDocument/definition"](err, locations, method, ...)
      end,
      ["textDocument/references"] = function(_, locations, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        ---@cast client -nil

        local filtered_items =
          filter(vim.lsp.util.locations_to_items(locations, client.offset_encoding), referencePredicate)

        if #filtered_items == 1 then
          vim.lsp.util.jump_to_location(filtered_items[1].user_data, client.offset_encoding)
        else
          local opts = {}
          require("telescope.pickers")
            .new(opts, {
              prompt_title = "LSP References",
              finder = require("telescope.finders").new_table({
                results = filtered_items,
                entry_maker = require("telescope.make_entry").gen_from_quickfix(opts),
              }),
              previewer = require("telescope.config").values.qflist_previewer(opts),
            })
            :find()
        end
      end,
    },
  },
}
