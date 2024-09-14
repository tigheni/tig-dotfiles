{config, ...}: {
  programs.starship.enable = true;
  xdg.configFile."starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/tig-dotfiles/starship/starship.toml";
}