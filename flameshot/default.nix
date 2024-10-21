{config, ...}: {
  services.flameshot.enable = true;
  xdg.configFile."flameshot/flameshot.ini".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/flameshot/flameshot.ini";
}
