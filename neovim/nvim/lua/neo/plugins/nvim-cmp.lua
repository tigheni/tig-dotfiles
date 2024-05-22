return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
    "onsails/lspkind.nvim",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local lspkind = require("lspkind")

    require("luasnip.loaders.from_vscode").lazy_load()
    vim.keymap.set("i", "<tab>", function()
      return luasnip.jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
    end, { expr = true, silent = true })
    vim.keymap.set("s", "<tab>", function()
      return luasnip.jump(1)
    end)
    vim.keymap.set({ "i", "s" }, "<s-tab>", function()
      return luasnip.jump(-1)
    end)

    luasnip.filetype_extend("typescript", { "typescriptreact" })

    cmp.setup({
      completion = {
        completeopt = "menu,menuone,noinsert",
      },
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(),
        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm(),
      }),
      sources = cmp.config.sources({
        { name = "luasnip" },
        { name = "nvim_lsp" },
        { name = "buffer" },
        { name = "path" },
      }),
      formatting = {
        format = lspkind.cmp_format({
          maxwidth = 50,
          ellipsis_char = "...",
        }),
      },
    })

    cmp.setup.cmdline({ "/", "?" }, {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })

    cmp.setup.cmdline(":", {
      mapping = {
        ["<C-k>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "c" }),
        ["<C-j>"] = cmp.mapping(cmp.mapping.select_next_item(), { "c" }),
        ["<C-e>"] = cmp.mapping(cmp.mapping.abort(), { "c" }),
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
            cmp.select_prev_item()
          end
          fallback()
        end, { "c" }),
        ["<tab>"] = cmp.mapping(cmp.mapping.confirm(), { "c" }),
      },
      sources = cmp.config.sources({
        { name = "cmdline" },
      }),
    })
  end,
}
