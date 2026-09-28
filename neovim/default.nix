{
  pkgs,
  username,
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
  };

  # Language servers, linters and formatters driven by config/nvim.
  users.users.${username}.packages = with pkgs; [
    gcc
    gnumake
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
    vtsls
    gopls
    golangci-lint
    typos-lsp
    hyprls
  ];
}
