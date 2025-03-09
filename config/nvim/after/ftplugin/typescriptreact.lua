local function toggle_use_client()
  if string.find(vim.fn.getline(1), "use client") then
    vim.api.nvim_buf_set_lines(0, 0, 2, false, {})
  else
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { '"use client";', "" })
  end
end

vim.keymap.set("n", "<leader>au", toggle_use_client, { desc = "Toggle use client" })
