return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local oil = require("oil")
    oil.setup({
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      prompt_save_on_select_new_entry = false,
      lsp_file_methods = {
        autosave_changes = true,
      },
      keymaps = {
        ["<C-s>"] = false,
        ["q"] = "actions.close",
      },
    })
    vim.keymap.set("n", "<leader>e", oil.toggle_float, { desc = "Toggle oil float" })
  end,
}
