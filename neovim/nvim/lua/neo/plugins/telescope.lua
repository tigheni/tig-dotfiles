return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        require("telescope").load_extension("fzf")
      end,
    },
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")
    local action_layout = require("telescope.actions.layout")
    local spectre = require("spectre")

    telescope.setup({
      pickers = {
        oldfiles = { cwd_only = true, previewer = false },
        find_files = { previewer = false },
        buffers = { sort_mru = true, ignore_current_buffer = true },
        lsp_references = {
          include_declaration = false,
          show_line = false,
        },
      },
      defaults = {
        vimgrep_arguments = {
          -- required
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          -- optional
          "--fixed-strings",
          "--hidden",
          "--glob=!.git/",
        },
        path_display = { "filename_first" },
        mappings = {
          i = {
            ["<C-k>"] = "move_selection_previous",
            ["<C-j>"] = "move_selection_next",
            ["<C-p>"] = function()
              spectre.open({ search_text = string.sub(vim.api.nvim_get_current_line(), 3) })
              vim.cmd("norm! jj")
            end,
            ["<esc>"] = "close",
            ["<M-p>"] = action_layout.toggle_preview,
            ["<C-y>"] = function()
              local entry = require("telescope.actions.state").get_selected_entry()
              vim.fn.setreg("+", entry.text or entry.value)
            end,
          },
        },
        layout_config = {
          prompt_position = "top",
        },
        sorting_strategy = "ascending",
      },
    })

    vim.keymap.set("n", "gt", builtin.lsp_type_definitions, { desc = "Show LSP type definitions" })
    vim.keymap.set("n", "<leader>sG", builtin.live_grep, { desc = "Telescope: Grep (case sensitive)" })
    vim.keymap.set("n", "<leader><space>", builtin.find_files, { desc = "Telescope: Git Files" })
    vim.keymap.set("n", "<leader>ss", builtin.lsp_document_symbols, { desc = "Telescope: Document Symbols" })
    vim.keymap.set("n", "<leader>sb", builtin.current_buffer_fuzzy_find, { desc = "Telescope: Search Buffer" })
    vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "Telescope: Resume" })
    vim.keymap.set("n", "<leader>r", builtin.oldfiles, { desc = "Telescope: Recent Files" })
    vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Telescope: Key Maps" })
    vim.keymap.set("n", "<leader>sc", builtin.commands, { desc = "Telescope: Commands" })
    vim.keymap.set("n", "<leader>sj", builtin.git_commits, { desc = "Telescope: Commits" })
    vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Telescope: Help Tags" })
    vim.keymap.set("n", "<leader>sD", builtin.diagnostics, { desc = "Show workspace diagnostics" })

    vim.keymap.set("n", "<leader>sn", function()
      builtin.find_files({ cwd = vim.env.HOME .. "/Projects/dotfiles" })
    end, { desc = "Telescope: Dotfiles" })

    vim.keymap.set("n", "<leader>sw", function()
      builtin.live_grep({ additional_args = { "--smart-case" }, default_text = vim.fn.expand("<cword>") })
    end, { desc = "Telescope: Grep word under cursor (smart case)" })

    vim.keymap.set("n", "<leader>sg", function()
      builtin.live_grep({ additional_args = { "--smart-case" } })
    end, { desc = "Telescope: Grep (smart case)" })

    vim.keymap.set("n", "<leader>sd", function()
      builtin.diagnostics({ bufnr = 0 })
    end, { desc = "Show buffer diagnostics" })
  end,
}
