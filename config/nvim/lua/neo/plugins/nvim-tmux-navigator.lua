return {
  "alexghergh/nvim-tmux-navigation",
  config = function()
    local nvim_tmux_nav = require("nvim-tmux-navigation")

    vim.keymap.set({ "n", "x" }, "<M-m>", nvim_tmux_nav.NvimTmuxNavigateLeft)
    vim.keymap.set({ "n", "x" }, "<M-n>", nvim_tmux_nav.NvimTmuxNavigateDown)
    vim.keymap.set({ "n", "x" }, "<M-e>", nvim_tmux_nav.NvimTmuxNavigateUp)
    vim.keymap.set({ "n", "x" }, "<M-i>", nvim_tmux_nav.NvimTmuxNavigateRight)
  end,
}
