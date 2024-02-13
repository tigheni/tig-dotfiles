return {
  "backdround/global-note.nvim",
  config = function()
    local global_note = require("global-note")
    global_note.setup({
      post_open = function(buffer_id)
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buffer_id, silent = true })
      end,
    })

    vim.keymap.set("n", "<leader>y", global_note.toggle_note, {
      desc = "Toggle global note",
    })
  end,
}
