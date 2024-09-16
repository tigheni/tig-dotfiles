{config, ...}: {
  programs.kitty.enable = true;
  xdg.configFile."kitty/kitty.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/kitty/kitty.conf";
}
