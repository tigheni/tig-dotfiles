{pkgs, ...}: {
  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-wlr;
  };
  programs.hyprlock.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  networking.networkmanager.enable = true;


  # Enable PipeWire for audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Disable PulseAudio since we're using PipeWire
  services.pulseaudio.enable = false;

  services.gvfs.enable = true;
  services.devmon.enable = true;
  services.udisks2.enable = true;

  users.users.tig = {
    packages = with pkgs; [
      dunst
      brightnessctl
      wl-clipboard
      wl-gammarelay-rs
      rofi-wayland
      clipse
      grim
      hyprpicker
      hyprpaper
      nautilus
      bibata-cursors
      networkmanagerapplet
      pavucontrol
    ];
  };

  services.ddccontrol.enable = true;
  hardware.i2c.enable = true;
  users.users.tig.extraGroups = ["i2c"];
}
