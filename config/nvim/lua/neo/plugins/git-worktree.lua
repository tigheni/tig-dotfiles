return {
  "ThePrimeagen/git-worktree.nvim",
  config = function()
    local worktree = require("git-worktree")
    vim.keymap.set("n", "<leader>gts", function()
      worktree.create_worktree("blametree", "blametree", "origin")
    end, { desc = "Create worktree" })

    vim.keymap.set("n", "<leader>gtr", function()
      require("git-worktree").switch_worktree(vim.fn.fnamemodify(vim.fn.getcwd(), ":h"))
      worktree.delete_worktree("blametree")
    end, { desc = "Delete worktree" })
  end,
}
