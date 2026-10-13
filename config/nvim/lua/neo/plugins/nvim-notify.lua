return {
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  config = function()
    local notify = require("notify")
    notify.setup({ render = "minimal", stages = "static" })

    vim.fn.jobstart("curl -s --max-time 5 https://zenquotes.io/api/random | jq -r '.[0] | \"\\(.q) - \\(.a)\"'", {
      stdout_buffered = true,
      on_stdout = function(_, data)
        local quote = data[1]
        if quote and quote ~= "" and quote ~= "null - null" then
          notify(quote, "info", { timeout = 10000 })
        end
      end,
    })
  end,
}
