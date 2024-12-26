return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local fzf = require("fzf-lua")

    fzf.setup({
      defaults = { formatter = "path.filename_first" },
      oldfiles = { cwd_only = true, include_current_session = true },
      keymap = {
        fzf = {
          ["ctrl-q"] = "select-all+accept",
          ["ctrl-d"] = "half-page-down",
          ["ctrl-u"] = "half-page-up",
        },
      },
      lsp = { includeDeclaration = false, jump_to_single_result = true },
      winopts = { preview = { delay = 0 } },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --fixed-strings --smart-case --max-columns=4096 -e",
        actions = {
          ["ctrl-space"] = { fzf.actions.grep_lgrep },
          ["ctrl-s"] = {
            fn = function(_, opts)
              fzf.actions.toggle_flag(_, vim.tbl_extend("force", opts, { toggle_flag = "--smart-case" }))
            end,
          },
          ["ctrl-t"] = {
            fn = function(_, opts)
              fzf.actions.toggle_flag(_, vim.tbl_extend("force", opts, { toggle_flag = "-g '!*.test.*'" }))
            end,
          },
          ["ctrl-g"] = {
            fn = function(_, opts)
              fzf.actions.toggle_flag(_, vim.tbl_extend("force", opts, { toggle_flag = "-g '!*generated*'" }))
            end,
          },
        },
      },
    })

    vim.keymap.set("n", "<leader>sc", fzf.commands, { desc = "Commands" })
    vim.keymap.set("n", "<leader>sd", fzf.diagnostics_document, { desc = "Buffer diagnostics" })
    vim.keymap.set("n", "<leader>sD", fzf.diagnostics_workspace, { desc = "Workspace diagnostics" })
    vim.keymap.set("n", "<leader>sg", fzf.live_grep, { desc = "Live Grep" })
    vim.keymap.set("n", "<leader>sh", fzf.helptags, { desc = "Help Tags" })
    vim.keymap.set("n", "<leader>sj", fzf.git_commits, { desc = "Commits" })
    vim.keymap.set("n", "<leader>sk", fzf.keymaps, { desc = "Key Maps" })
    vim.keymap.set("n", "<leader>sr", fzf.resume, { desc = "Resume" })
    vim.keymap.set("n", "<leader>ss", fzf.lsp_document_symbols, { desc = "Document Symbols" })
    vim.keymap.set("n", "<leader>sw", fzf.grep_cword, { desc = "Grep cword" })
    vim.keymap.set("x", "<leader>sw", fzf.grep_visual, { desc = "Grep visual" })

    vim.keymap.set("n", "<leader><space>", fzf.files, { desc = "Files" })
    vim.keymap.set("n", "<leader>r", fzf.oldfiles, { desc = "Recent Files" })

    vim.keymap.set("n", "gr", function()
      fzf.lsp_references({
        regex_filter = function(value)
          return not vim.startswith(value.text, "import")
            and not vim.startswith(string.sub(value.text, value.col - 2, value.col - 1), "</")
            and string.sub(value.text, 0, value.col - 1) ~= "export default "
        end,
      })
    end, { desc = "Show LSP references" })
    vim.keymap.set("n", "gt", fzf.lsp_typedefs, { desc = "Show LSP type definitions" })
  end,
}
