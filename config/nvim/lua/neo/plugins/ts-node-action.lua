return {
  "ckolkey/ts-node-action",
  dependencies = { "nvim-treesitter" },
  config = function()
    local tsna = require("ts-node-action")
    local actions = require("ts-node-action.actions")

    local operators = {
      ["!="] = "==",
      ["!=="] = "===",
      ["=="] = "!=",
      ["==="] = "!==",
      [">"] = "<",
      ["<"] = ">",
      [">="] = "<=",
      ["<="] = ">=",
    }

    local padding = {
      [","] = "%s ",
      [":"] = "%s ",
      ["{"] = "%s ",
      ["}"] = " %s",
    }

    tsna.setup({
      tsx = {
        ["property_identifier"] = actions.cycle_case(),
        ["string_fragment"] = actions.conceal_string(),
        ["binary_expression"] = actions.toggle_operator(operators),
        ["object"] = actions.toggle_multiline(padding),
        ["array"] = actions.toggle_multiline(padding),
        ["statement_block"] = actions.toggle_multiline(padding),
        ["object_pattern"] = actions.toggle_multiline(padding),
        ["object_type"] = actions.toggle_multiline(padding),
        ["formal_parameters"] = actions.toggle_multiline(padding),
        ["arguments"] = actions.toggle_multiline(padding),
        ["number"] = actions.toggle_int_readability(),
      },
    })

    vim.keymap.set({ "n" }, "<leader>o", tsna.node_action, { desc = "Trigger Node Action" })
  end,
}
