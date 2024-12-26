return {
  "saghen/blink.cmp",
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
  version = "*",
  opts = {
    keymap = {
      preset = "super-tab",
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
    },
    snippets = {
      expand = function(snippet)
        require("luasnip").lsp_expand(snippet)
      end,
      active = function(filter)
        if filter and filter.direction then
          return require("luasnip").jumpable(filter.direction)
        end
        return require("luasnip").in_snippet()
      end,
      jump = function(direction)
        require("luasnip").jump(direction)
      end,
    },
    sources = { default = { "lsp", "path", "luasnip", "buffer" } },
  },
}
