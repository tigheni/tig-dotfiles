{config,...} :{
  programs.waybar.enable = true;
  xdg.configFile."waybar/config".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/tig-dotfiles/waybar/config.jsonc";
  xdg.configFile."waybar/style.css".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/tig-dotfiles/waybar/style.css";
}