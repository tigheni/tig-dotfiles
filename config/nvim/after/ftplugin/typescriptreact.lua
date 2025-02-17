local function checkUseClient()
  local first_line = vim.fn.getline(1)
  return string.find(first_line, "use client")
end

local function addUseClient()
  local has_use_client = checkUseClient()
  if not has_use_client then
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { '"use client";', "" })
  end
end

vim.keymap.set("n", "<leader>au", function()
  addUseClient()
end, { buffer = 0, desc = "Add use client" })
