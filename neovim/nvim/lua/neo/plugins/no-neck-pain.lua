return {
  "shortcuts/no-neck-pain.nvim",
  config = function()
    require("no-neck-pain").setup({
      buffers = {
        setNames = true,
        right = {
          enabled = false,
        },
      },
      autocmds = {
        -- enableOnVimEnter = true,
      },
    })
    vim.keymap.set("n", "<leader>x", "<cmd>NoNeckPain<CR>")
  end,
}
