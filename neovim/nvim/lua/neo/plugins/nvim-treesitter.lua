return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = { { "windwp/nvim-ts-autotag", config = true }, "nvim-treesitter/nvim-treesitter-textobjects" },
  config = function()
    require("nvim-treesitter.configs").setup({
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>",
          node_incremental = "<CR>",
          node_decremental = "sd",
          scope_incremental = "sc",
        },
      },
      auto_install = true,
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ai"] = "@conditional.outer",
            ["ii"] = "@conditional.inner",
            ["ao"] = "@loop.outer",
            ["io"] = "@loop.inner",
            ["ac"] = "@call.outer",
            ["ic"] = "@call.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",

            --     const arr = [1, 2, 3, 4, 5];
            ["ae"] = "@assignment.outer", -- arr = [1, 2, 3, 4, 5]
            ["ie"] = "@assignment.inner", -- arr
            ["al"] = "@assignment.lhs", -- arr
            ["ar"] = "@assignment.rhs", -- [1, 2, 3, 4, 5]
          },
          selection_modes = {
            ["@assignment.outer"] = "V",
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader>an"] = "@parameter.inner",
          },
          swap_previous = {
            ["<leader>ap"] = "@parameter.inner",
          },
        },
      },
    })
  end,
}
