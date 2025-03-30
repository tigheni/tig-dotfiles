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
    snippets = { preset = "luasnip" },
    keymap = { preset = "enter" },
    completion = { keyword = { range = "full" } },
    cmdline = {
      keymap = { preset = "inherit", ["<CR>"] = { "accept_and_enter", "fallback" } },
      completion = { menu = { auto_show = true } },
    },
  },
}
