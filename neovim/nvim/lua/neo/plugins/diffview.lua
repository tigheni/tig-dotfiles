return {
  "sindrets/diffview.nvim",
  config = function()
    local diffview = require("diffview")
    local actions = require("diffview.actions")

    diffview.setup({
      enhanced_diff_hl = true,
      file_panel = {
        listing_style = "list",
        -- win_config = {
        --   width = 70,
        -- },
      },
      view = {
        merge_tool = {
          layout = "diff1_plain",
          disable_diagnostics = false,
        },
      },
      keymaps = {
        view = {
          { "n", "<leader>e", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle the file panel." } },
          { "n", "<leader>x", actions.restore_entry, { desc = "Restore entry to the state on the left side" } },
          { "n", "<leader>b", actions.toggle_stage_entry, { desc = "Toggle stage entry" } },
        },
        file_panel = {
          { "n", "<leader>e", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle the file panel." } },
          { "n", "x", actions.restore_entry, { desc = "Restore entry to the state on the left side" } },
        },
      },
      hooks = {
        diff_buf_win_enter = function(_, _, ctx)
          if ctx.layout_name:match("^diff2") then
            if ctx.symbol == "a" then
              vim.opt_local.winhl = table.concat({
                "DiffChange:DiffAddAsDelete",
                "DiffText:DiffDeleteText",
              }, ",")
            elseif ctx.symbol == "b" then
              vim.opt_local.winhl = table.concat({
                "DiffChange:DiffAdd",
                "DiffText:DiffAddText",
              }, ",")
            end
          end
        end,
      },
    })

    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#1c1c1c", fg = "#262626" })
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#303030" })
    vim.api.nvim_set_hl(0, "DiffAddAsDelete", { bg = "#303030" })
    vim.api.nvim_set_hl(0, "DiffDeleteText", { bg = "#4B1818" })
    vim.api.nvim_set_hl(0, "DiffAddText", { bg = "#005f00" })

    vim.keymap.set("n", "<leader>d", function()
      if next(require("diffview.lib").views) == nil then
        vim.cmd("DiffviewOpen")
      else
        vim.cmd("DiffviewClose")
      end
    end, { desc = "Toggle Diffview" })
  end,
}
