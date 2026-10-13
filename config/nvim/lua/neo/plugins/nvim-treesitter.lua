-- Textobject keymaps, set per buffer once treesitter is running in it
local select_keymaps = {
  ["af"] = "@function.outer",
  ["if"] = "@function.inner",
  ["ai"] = "@conditional.outer",
  ["ii"] = "@conditional.inner",
  ["ao"] = "@loop.outer",
  ["io"] = "@loop.inner",
  ["ac"] = "@call.outer",
  ["ic"] = "@call.inner",
  ["aa"] = "@attribute.outer",
  ["ia"] = "@attribute.inner",

  --     const arr = [1, 2, 3, 4, 5];
  ["ae"] = "@assignment.outer", -- arr = [1, 2, 3, 4, 5]
  ["ie"] = "@assignment.inner", -- arr
  ["al"] = "@assignment.lhs", -- arr
  ["ar"] = "@assignment.rhs", -- [1, 2, 3, 4, 5]
}

local function attach(buf)
  if not pcall(vim.treesitter.start, buf) then
    return
  end
  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

  local select = require("nvim-treesitter-textobjects.select")
  local swap = require("nvim-treesitter-textobjects.swap")
  for lhs, query in pairs(select_keymaps) do
    vim.keymap.set({ "x", "o" }, lhs, function()
      select.select_textobject(query, "textobjects")
    end, { buffer = buf, desc = query })
  end
  vim.keymap.set("n", "<leader>a>", function()
    swap.swap_next("@parameter.inner")
  end, { buffer = buf, desc = "Swap next parameter" })
  vim.keymap.set("n", "<leader>a<", function()
    swap.swap_previous("@parameter.inner")
  end, { buffer = buf, desc = "Swap previous parameter" })

  -- Incremental selection via the builtin an/in node selection
  vim.keymap.set("n", "<CR>", "van", { buffer = buf, remap = true, desc = "Start node selection" })
  vim.keymap.set("x", "<CR>", "an", { buffer = buf, remap = true, desc = "Expand to parent node" })
  vim.keymap.set("x", "sd", "in", { buffer = buf, remap = true, desc = "Shrink to child node" })
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
      { "windwp/nvim-ts-autotag", config = true },
    },
    config = function()
      local ts = require("nvim-treesitter")

      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
          selection_modes = {
            ["@assignment.outer"] = "V",
          },
        },
      })

      vim.treesitter.language.register("bash", "zsh")

      -- Start treesitter on every filetype that has a parser, installing
      -- missing ones on first use (replaces master's auto_install)
      local available = ts.get_available()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_attach", { clear = true }),
        callback = function(event)
          local lang = vim.treesitter.language.get_lang(event.match)
          if not lang then
            return
          end
          if vim.list_contains(available, lang) and not vim.list_contains(ts.get_installed(), lang) then
            ts.install(lang):await(function()
              vim.schedule(function()
                if vim.api.nvim_buf_is_valid(event.buf) then
                  attach(event.buf)
                end
              end)
            end)
          else
            attach(event.buf)
          end
        end,
      })
    end,
  },
}
