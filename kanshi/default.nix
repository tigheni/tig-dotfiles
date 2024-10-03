{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    kanshi
  ];

  xdg.configFile."kanshi/config".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/kanshi/config";
}
