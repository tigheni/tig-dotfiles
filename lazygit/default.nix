{config, ...}: {
  programs.lazygit.enable = true;
  xdg.configFile."lazygit/config.yml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/lazygit/config.yml";
}
