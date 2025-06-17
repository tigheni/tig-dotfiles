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
  -- use a release tag to download pre-built binaries
  version = "*",
  opts = {
    enabled = function()
      return not vim.list_contains({ "DressingInput" }, vim.bo.filetype)
        and vim.bo.buftype ~= "prompt"
        and vim.b.completion ~= false
    end,
    snippets = { preset = "luasnip" },
    keymap = { preset = "enter" },
    completion = {
      keyword = { range = "full" },
      -- https://github.com/Saghen/blink.cmp/issues/1847
      accept = { dot_repeat = false },
      documentation = { auto_show = true, auto_show_delay_ms = 500 },
    },
    cmdline = {
      keymap = {
        preset = "inherit",
        ["<CR>"] = { "accept_and_enter", "fallback" },
      },
      completion = {
        menu = { auto_show = true },
        list = {
          selection = {
            preselect = function()
              return vim.fn.getcmdtype() == ":"
            end,
          },
        },
      },
    },
  },
}
