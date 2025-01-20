return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local oil = require("oil")
    oil.setup({
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      prompt_save_on_select_new_entry = false,
      watch_for_changes = true,
      lsp_file_methods = {
        autosave_changes = true,
      },
      git = {
        add = function(path)
          return vim.startswith(path, "/home/abdennour/Projects/dotfiles")
        end,
      },
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name)
          return name == ".."
        end,
      },
      keymaps = {
        ["<C-s>"] = false,
        ["q"] = "actions.close",
      },
      float = { max_width = 0.8 },
    })
    vim.keymap.set("n", "<leader>e", oil.toggle_float, { desc = "Toggle oil float" })
  end,
}
