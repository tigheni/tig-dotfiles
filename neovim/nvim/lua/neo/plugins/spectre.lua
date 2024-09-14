return {
  "nvim-pack/nvim-spectre",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    local spectre = require("spectre")

    spectre.setup({
      is_insert_mode = true,
      highlight = {
        replace = "DiffChange",
      },
    })

    vim.keymap.set("n", "<leader>sp", spectre.toggle, { desc = "Toggle Spectre" })
    vim.keymap.set("v", "<leader>sp", spectre.open_visual, { desc = "Search current word" })
    vim.keymap.set("n", "<leader>su", function()
      spectre.open_visual({ select_word = true })
    end, { desc = "Search current word" })
    vim.keymap.set("n", "<leader>sf", function()
      spectre.open_file_search({ select_word = true })
    end, { desc = "Search on current file" })
  end,
}
