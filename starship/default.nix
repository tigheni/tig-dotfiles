{config, ...}: {
  programs.starship.enable = true;
  xdg.configFile."starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/starship/starship.toml";
}
