return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
      }

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("lint", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          javascript = { "prettierd" },
          typescript = { "prettierd" },
          javascriptreact = { "prettierd" },
          typescriptreact = { "prettierd" },
          css = { "prettierd" },
          scss = { "prettierd" },
          html = { "prettierd" },
          json = { "prettierd" },
          yaml = { "prettierd" },
          markdown = { "prettierd" },
          lua = { "stylua" },
          nix = { "alejandra" },
        },
        format_on_save = function()
          if vim.g.disable_autoformat then
            return
          end
          return {}
        end,
      })

      vim.keymap.set("n", "<leader>h", function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
      end, { desc = "Toggle autoformatting" })

      vim.keymap.set({ "n", "v" }, "<leader>f", conform.format, { desc = "Format file or range (in visual mode)" })
    end,
  },
}
