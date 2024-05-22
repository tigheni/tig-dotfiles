{
  config,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    extraConfig = ''
      # This is an example configuration file for hyprland
    '';
  };

  # trace: warning: tig profile: You have enabled hyprland.systemd.enable or listed plugins in hyprland.plugins
  # but do not have any configuration in hyprland.settings or hyprland.extraConfig. This is almost certainly a mistake.

  # lib.file.mkOutOfStoreSymlink = path:
  # let
  #   pathStr = toString path;
  #   name = hm.strings.storeFileName (baseNameOf pathStr);
  # in
  #   pkgs.runCommandLocal name {} ''ln -s ${escapeShellArg pathStr} $out'';

  home.packages = with pkgs; [
    swaynotificationcenter
    waybar
    wofi
  ];

  xdg.configFile."hypr/hyprland.conf".source = config.lib.file.mkOutOfStoreSymlink ./hyprland.conf;
  xdg.configFile.waybar = {
    source =
      config.lib.file.mkOutOfStoreSymlink ./waybar;
    recursive = true;
  };
}
