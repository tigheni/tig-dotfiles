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
    on_attach = function()
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

      vim.keymap.set("n", "<leader>ai", "<cmd>VtsExec add_missing_imports<CR>", { desc = "Add missing imports" })
      vim.keymap.set("n", "<leader>ar", "<cmd>VtsExec remove_unused<CR>", { desc = "Remove unused variables" })
      vim.keymap.set("n", "<leader>ao", "<cmd>VtsExec organize_imports<CR>", { desc = "Organize imports" })
    end,
  },
}
