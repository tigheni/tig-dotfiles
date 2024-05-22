{config, ...}: {
  programs.wezterm.enable = true;
  xdg.configFile."wezterm/wezterm.lua".source = config.lib.file.mkOutOfStoreSymlink ./wezterm.lua;
}
