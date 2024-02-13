-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", {}),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("last_loc", {}),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("close_with_q", {}),
  pattern = {
    "PlenaryTestPopup",
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "query",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "neotest-output",
    "checkhealth",
    "neotest-summary",
    "neotest-output-panel",
    "vim",
    "CodeAction",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Disable New Line Comment
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("disable_new_line_comment", {}),
  callback = function()
    vim.opt.formatoptions:remove({ "c", "o" })
  end,
  desc = "Disable New Line Comment",
})

-- Enable editing quifkfix list like a normal buffer
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("enable_quickfix_edit", { clear = true }),
  desc = "allow updating quickfix window",
  pattern = "quickfix",
  callback = function()
    vim.bo.modifiable = true
    -- :vimgrep's quickfix window display format now includes start and end column (in vim and nvim) so adding 2nd format to match that
    vim.bo.errorformat = "%f|%l col %c| %m,%f|%l col %c-%k| %m"
    vim.keymap.set(
      "n",
      "<C-s>",
      '<Cmd>cgetbuffer|set nomodified|echo "quickfix/location list updated"<CR>',
      { buffer = true, desc = "Update quickfix/location list with changes made in quickfix window" }
    )
  end,
})

-- Abbreviations
vim.cmd([[
inoreabbrev dont don't
inoreabbrev prpos props
inoreabbrev rbm # TODO: remove before merging
inoreabbrev cbm # TODO: change before merging
inoreabbrev ubm # TODO: uncomment before merging
inoreabbrev stp // STOPSHIP
]])

vim.fn.setreg("c", "vaqSBvaqSbiclsx")

vim.filetype.add({
  filename = { ["hyprland.conf"] = "hyprlang" },
})

vim.api.nvim_create_user_command("LintInfo", function()
  vim.print(require("lint").get_running())
end, {})
