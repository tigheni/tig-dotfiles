return {
  "folke/tokyonight.nvim",
  priority = 1000, -- make sure to load this before other plugins
  config = function()
    -- Enable true colors
    vim.opt.termguicolors = true

    -- Safe require and fallback to default colorscheme if tokyonight is missing
    local ok, tokyonight = pcall(require, "tokyonight")
    if not ok then
      vim.notify("TokyoNight colorscheme not found!", vim.log.levels.WARN)
      return
    end

    -- Customize TokyoNight options
    require("tokyonight").setup({
      style = "night", -- Available options: "storm", "night", "day", "moon"
      transparent = false, -- Disable transparency (keep background)
      styles = {
        floats = "normal", -- Keep normal background for floating windows
      },
      on_highlights = function(hl, colors)
        -- Customize specific highlight groups
        hl.Normal = { bg = colors.bg, fg = colors.fg }        -- Use theme background and foreground
        hl.NormalFloat = { bg = colors.bg_float, fg = colors.fg } -- Use theme background for floating windows
        hl.LineNr = { fg = colors.blue }   -- Set line numbers to blue
        -- Add more highlights here as needed
      end,
    })

    -- Apply the colorscheme
    vim.cmd.colorscheme("tokyonight")
  end,
}
