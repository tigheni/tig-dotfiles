local M = {}

M.map_action = function(keymap, actions, desc)
  desc = desc or actions[1]
  vim.keymap.set({ "n", "v" }, keymap, function()
    vim.lsp.buf.code_action({
      filter = function(action)
        for _, v in ipairs(actions) do
          if vim.endswith(action.title, v) then
            return true
          end
        end
        return false
      end,
      apply = true,
    })
  end, { desc = desc })
end

return M
