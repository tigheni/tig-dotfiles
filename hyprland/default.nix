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

  services.gvfs.enable = true;
  services.devmon.enable = true;
  services.udisks2.enable = true;

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
      bibata-cursors
    ];
  };

  services.ddccontrol.enable = true;
  hardware.i2c.enable = true;
  users.users.abdennour.extraGroups = ["i2c"];
}
