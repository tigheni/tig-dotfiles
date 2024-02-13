{pkgs, ...}: {
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.wayland = false;
  services.xserver.xkb.options = "terminate:ctrl_alt_bksp, lv3:ralt_switch, caps:escape_shifted_capslock";

  services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];
  programs.dconf.enable = true;

  users.users.abdennour = {
    packages = with pkgs; [
      gnome.gnome-tweaks
      gnome.gnome-shell
      gnome.gnome-shell-extensions
      gnomeExtensions.appindicator
      gnomeExtensions.vitals
      gnomeExtensions.hide-minimized
      gnomeExtensions.notification-timeout
      gnome.dconf-editor
    ];
  };

  system.userActivationScripts.linktosharedfolder.text = ''
    if [[ ! -h "$HOME/Pictures/Screenshots" ]]; then
      ln -s /dev/null  "$HOME/Pictures/Screenshots"
    fi
  '';
}
