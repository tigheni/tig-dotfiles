{
  config,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
    # not working
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    extraPackages = with pkgs; [
      gcc
      pyright
      lua-language-server
      vscode-langservers-extracted
      tailwindcss-language-server
      yaml-language-server
      alejandra
      stylua
      nixd
      emmet-language-server
      prettierd
      taplo
      gopls
      golangci-lint
      typos-lsp
    ];
  };
  xdg.configFile.nvim = {
    source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/neovim/nvim";
    recursive = true;
  };
}
