return {
  "kevinhwang91/nvim-bqf",
  enabled = false,
  dependencies = {
    "junegunn/fzf",
    build = function()
      vim.fn["fzf#install"]()
    end,
  },
}
