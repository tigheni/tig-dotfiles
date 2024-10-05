return {
  "bluz71/vim-nightfly-guicolors",
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    require("nightfly").custom_colors({ bg = "#000000" })

    vim.cmd.colorscheme("nightfly")

    vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal" })
    vim.api.nvim_set_hl(0, "LineNr", { link = "NightflyBlue" })
    vim.api.nvim_set_hl(0, "TreesitterContextBottom", {})
  end,
}
