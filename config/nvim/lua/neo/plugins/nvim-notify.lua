return {
  "rcarriga/nvim-notify",
  config = function()
    local notify = require("notify")
    notify.setup({ render = "minimal", stages = "static" })

    vim.fn.jobstart("curl -s https://zenquotes.io/api/random | jq -r '.[0] | \"\\(.q) - \\(.a)\"'", {
      stdout_buffered = true,
      on_stdout = function(_, data)
        notify(data[1], "info", { timeout = 10000 })
      end,
    })
  end,
}
