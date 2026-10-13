local flake = string.format('(builtins.getFlake "%s")', vim.env.DOTFILES_DIR or vim.fn.expand("~/tig-dotfiles"))

return {
  "nixd",
  {
    settings = {
      nixd = {
        nixpkgs = { expr = "import " .. flake .. ".inputs.nixpkgs { }" },
        formatting = { command = { "alejandra" } },
        options = {
          nixos = { expr = flake .. ".nixosConfigurations.nixos.options" },
        },
      },
    },
  },
}
