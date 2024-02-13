return {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        panel = { enabled = false },
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = false,
            accept_word = false,
          },
        },
        filetypes = {
          markdown = true,
        },
      })

      local suggestion = require("copilot.suggestion")
      vim.keymap.set("i", "<M-l>", suggestion.accept)
      vim.keymap.set("i", "<M-h>", suggestion.accept_word)
      vim.keymap.set("i", "<M-i>", suggestion.accept)
      vim.keymap.set("i", "<M-m>", suggestion.accept_word)
      -- vim.keymap.set("i", "<C-y>", suggestion.accept)
      -- vim.keymap.set("i", "<C-;>", suggestion.accept_word)
    end,
  },
  -- {
  --   "Exafunction/codeium.vim",
  -- /home/abdennour/.cache/nvim/codeium/bin/1.6.7/language_server_linux_x64
  -- event = "InsertEnter",
  --   config = function()
  --   require("codeium").setup({
  --     tools = {
  --       language_server = "/etc/profiles/per-user/abdennour/bin/codeium_language_server",
  --     },
  --   })
  --     vim.g.codeium_bin = "/etc/profiles/per-user/abdennour/bin/codeium_language_server"
  --     vim.g.codeium_disable_bindings = 1
  --     -- vim.g.codeium_no_map_tab = 1
  --   end,
  -- },
}
