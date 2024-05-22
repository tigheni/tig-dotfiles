return {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    opts = {
      panel = { enabled = false },
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept_word = "<M-h>",
        },
      },
      filetypes = {
        markdown = true,
      },
    },
  },
  
}
