{config, ...}: {
  programs.waybar.enable = true;
  xdg.configFile."waybar/config.jsonc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/waybar/config.jsonc";
  xdg.configFile."waybar/style.css".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/waybar/style.css";
}
