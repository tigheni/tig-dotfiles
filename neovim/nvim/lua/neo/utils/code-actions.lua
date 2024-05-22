local M = {}

local function get_current_line_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = row - 1 })
  local lsp_diagnostics = vim.tbl_map(function(value)
    local diagnostic = {
      code = value.code,
      message = value.message,
      severity = value.severity,
      source = value.source,
      range = {
        start = {
          character = value.col,
          line = value.lnum,
        },
        ["end"] = {
          character = value.end_col,
          line = value.end_lnum,
        },
      },
    }
    local lsp_data = vim.tbl_get(value, "user_data", "lsp")

    if lsp_data then
      diagnostic.codeDescription = lsp_data.codeDescription
      diagnostic.tags = lsp_data.tags
      diagnostic.relatedInformation = lsp_data.relatedInformation
      diagnostic.data = lsp_data.data
    end

    return diagnostic
  end, diagnostics)

  return lsp_diagnostics
end

local function range_from_selection(bufnr, mode)
  local start = vim.fn.getpos("v")
  local end_ = vim.fn.getpos(".")
  local start_row = start[2]
  local start_col = start[3]
  local end_row = end_[2]
  local end_col = end_[3]

  -- A user can start visual selection at the end and move backwards
  -- Normalize the range to start < end
  if start_row == end_row and end_col < start_col then
    end_col, start_col = start_col, end_col
  elseif end_row < start_row then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end
  if mode == "V" then
    start_col = 1
    local lines = vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, true)
    end_col = #lines[1]
  end
  return {
    ["start"] = { start_row, start_col - 1 },
    ["end"] = { end_row, end_col - 1 },
  }
end

local function apply_action(action, client, ctx)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  elseif action.command then
    local command = type(action.command) == "table" and action.command or action
    local fn = client.commands[command.command] or vim.lsp.commands[command.command]

    if fn then
      ctx.client_id = client.id
      fn(command, ctx)
    else
      local params = {
        command = command.command,
        arguments = command.arguments,
        workDoneToken = command.workDoneToken,
      }
      client.request("workspace/executeCommand", params, nil, ctx.bufnr)
    end
  end
end

local function handle_action(action, client, context)
  local supports_resolve = client and vim.tbl_get(client.server_capabilities, "codeActionProvider", "resolveProvider")

  if not action.edit and supports_resolve then
    client.request("codeAction/resolve", action, function(err, resolved_action)
      if err then
        vim.notify(err.code .. ": " .. err.message, vim.log.levels.ERROR)
        return
      end
      apply_action(resolved_action, client, context)
    end, context.bufnr)
  else
    apply_action(action, client, context)
  end
end

local function get_params()
  local mode = vim.api.nvim_get_mode().mode
  local params = {}
  if mode == "v" or mode == "V" then
    local range = range_from_selection(0, mode)
    params = vim.lsp.util.make_given_range_params(range.start, range["end"])
  else
    params = vim.lsp.util.make_range_params()
  end

  params.context = {
    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
    diagnostics = get_current_line_diagnostics(),
  }

  return params
end

local function action_matches_prefix(action, prefix)
  local title = vim.fn.trim(action.title)
  for _, v in ipairs(prefix) do
    if vim.startswith(title, v) then
      return true
    end
  end
  return false
end

M.apply = function(prefix)
  local bufnr = vim.api.nvim_get_current_buf()
  local params = get_params()

  vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", params, function(results)
    if not results then
      return
    end

    local context = { bufnr = bufnr, method = "textDocument/codeAction", params = params }
    for client_id, result in pairs(results) do
      for _, action in pairs(result.result or {}) do
        if action_matches_prefix(action, prefix) then
          action.title = action.title:gsub("\r\n", "\\r\\n")
          action.title = action.title:gsub("\n", "\\n")
          local client = vim.lsp.get_client_by_id(client_id)
          handle_action(action, client, context)
          return
        end
      end
    end
  end)
end

return M
