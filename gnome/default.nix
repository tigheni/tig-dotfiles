{pkgs, ...}: {
  services.udev.packages = with pkgs; [gnome-settings-daemon];
  programs.dconf.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver ={
    enable = true;
    xkb = {
      layout = "us";
      variant = "symbolic";
      options = "terminate:ctrl_alt_bksp, lv3:ralt_switch, caps:escape_shifted_capslock";
    };
    displayManager = {
      gdm = {
        enable = true;
        wayland = false;
      };

   };
  };

  users.users.tig = {
    packages = with pkgs; [
      gnome-tweaks
      gnomeExtensions.gsconnect
      dconf-editor
      gnomeExtensions.vitals
      gnomeExtensions.notification-timeout
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.blur-my-shell
      gnomeExtensions.dash-to-dock
      gnomeExtensions.hide-keyboard-layout
      gnome46Extensions."openweather-extension@penguin-teal.github.io"
      gnomeExtensions.no-titlebar-when-maximized
    ];
  };

  environment.gnome.excludePackages = (with pkgs; [
  gnome-tour
  epiphany # web browser
  geary # email reader
  tali # poker game
  iagno # go game
  hitori # sudoku game
  atomix # puzzle game
  totem # video player
  ]);
  system.userActivationScripts.linktosharedfolder.text = ''
    if [[ ! -h "$HOME/Pictures/Screenshots" ]]; then
      ln -s /dev/null  "$HOME/Pictures/Screenshots"
    fi
  '';
}