return {
  "saghen/blink.cmp",
  version = "*",
  dependencies = {
    "rafamadriz/friendly-snippets",
    {
      "L3MON4D3/LuaSnip",
      version = "v2.*",
      build = "make install_jsregexp",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end,
    },
  },
  opts = {
    keymap = {
      preset = "enter",
      ["<CR>"] = {
        function(cmp)
          return cmp.accept({
            callback = function()
              if vim.fn.getcmdtype() ~= "" then
                vim.api.nvim_feedkeys("\n", "n", true)
              end
            end,
          })
        end,
        "fallback",
      },
      ["<Tab>"] = {
        function(cmp)
          if vim.fn.getcmdtype() ~= "" then
            return cmp.accept()
          else
            return cmp.snippet_forward()
          end
        end,
        "fallback",
      },
    },
    snippets = { preset = "luasnip" },
  },
}
