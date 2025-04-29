return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
  config = function()
    vim.g.skip_ts_context_commentstring_module = true

    require("Comment").setup({
      -- for commenting tsx and jsx files
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      ignore = "^$",
    })
  end,
}
