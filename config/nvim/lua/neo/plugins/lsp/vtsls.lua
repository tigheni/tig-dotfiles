local map_action = require("neo.plugins.lsp.utils").map_action

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
          includePackageJsonAutoImports = "off",
          autoImportFileExcludePatterns = {
            "@headlessui/react",
            "@radix-ui",
            "chart.js",
            "Input.tsx",
            "Button.tsx",
            "react-leaflet",
            "leaflet",
          },
          preferTypeOnlyAutoImports = true,
        },
        updateImportsOnFileMove = {
          enabled = "always",
        },
      },
    },
  },
  keymaps = function(bufnr)
    map_action(
      bufnr,
      "<leader>aa",
      { "Remove braces from arrow function", "Add braces to arrow function" },
      "Toggle arrow function braces"
    )
    map_action(bufnr, "<leader>ak", { "Inline variable" })
    map_action(bufnr, "<leader>ae", { "Extract to constant in enclosing scope", "Extract to type alias" })
    map_action(bufnr, "<leader>aE", { "Extract to constant in module scope" })
    map_action(bufnr, "<leader>af", { "Extract to function in module scope" })
    map_action(bufnr, "<leader>am", { "Convert to named function" })
    map_action(bufnr, "<leader>an", { "Move to file" })
    map_action(bufnr, "<leader>aN", { "Move to a new file" })
    map_action(bufnr, "<leader>ad", { "Convert named export to default export" })

    local function map(lhs, cmd, desc)
      vim.keymap.set("n", lhs, "<cmd>VtsExec " .. cmd .. "<CR>", { buffer = bufnr, desc = desc })
    end
    map("<leader>ai", "add_missing_imports", "Add missing imports")
    map("<leader>ar", "remove_unused", "Remove unused variables")
    map("<leader>ao", "organize_imports", "Organize imports")
  end,
}
