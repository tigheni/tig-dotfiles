return {
  "NeogitOrg/neogit",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>gl", "<cmd>Neogit<cr>", desc = "Neogit" },
    { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit commit" },
    { "<leader>gh", "<cmd>Neogit branch<cr>", desc = "Neogit branch" },
  },
  opts = {
    commit_editor = {
      kind = "vsplit",
      show_staged_diff = false,
    },
    sections = {
      stashes = { folded = false },
      recent = { folded = false },
    },
  },
}
