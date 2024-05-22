{
  config,
  pkgs,
  ...
}: let
  unstable =
    import <nixos-unstable>
    {config = {allowUnfree = true;};};
in {
  home.packages =
    (with pkgs; [
      lua-language-server
      vscode-langservers-extracted
      tailwindcss-language-server
      yaml-language-server
      prettierd
      biome
      eslint_d
      alejandra
      stylua
      nil
    ])
    ++ (
      with unstable; [
        emmet-language-server
      ]
    );

  programs.neovim = {
    enable = true;
    # not working
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
  };
  xdg.configFile.nvim = {
    source =
      config.lib.file.mkOutOfStoreSymlink ./nvim;
    recursive = true;
  };
}
