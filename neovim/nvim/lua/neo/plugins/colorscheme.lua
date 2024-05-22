return {
  "bluz71/vim-nightfly-guicolors",
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    vim.cmd.colorscheme("nightfly")
    vim.api.nvim_set_hl(0, "LineNr", { fg = "#82aaff" })
  end,
  commit = "255f433f617e3ace2f1fad4823452620e8d27c7d",
}
