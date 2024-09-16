{pkgs, ...}: {
  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-wlr;
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.pipewire.enable = true;

  users.users.abdennour = {
    packages = with pkgs; [
      dunst
      brightnessctl
      wl-clipboard
      wl-gammarelay-rs
      nemo
      wofi
      clipse
      swaybg
      grim
      hyprpicker
    ];
  };

  home-manager.users.abdennour = {config, ...}: {
    imports = [../waybar];
    xdg.configFile."hypr/hyprland.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/hyprland/hyprland.conf";

    services.flameshot = {
      enable = true;
      settings = {
        General = {
          showDesktopNotification = false;
          saveLastRegion = true;
          showHelp = false;
        };
      };
    };

    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    gtk.enable = true;
  };
}
