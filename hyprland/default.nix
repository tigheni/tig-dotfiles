{pkgs, ...}: {
  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-wlr;
  };
  programs.hyprlock.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.pipewire.enable = true;

  services.devmon.enable = true;

  users.users.abdennour = {
    packages = with pkgs; [
      dunst
      brightnessctl
      wl-clipboard
      wl-gammarelay-rs
      wofi
      clipse
      grim
      hyprpicker
      nautilus
    ];
  };

  programs.zsh.loginShellInit = ''
    if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec Hyprland
    fi
  '';

  home-manager.users.abdennour = {config, ...}: {
    imports = [../waybar];
    xdg.configFile."hypr/hyprland.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/hyprland/hyprland.conf";
    xdg.configFile."hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/hyprland/hyprlock.conf";
    xdg.configFile."hypr/hypridle.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/hyprland/hypridle.conf";

    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    gtk.enable = true;
  };
}
