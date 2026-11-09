_: {
  # Nothing else belongs here. The Hyprland module already sets
  # xdg.portal.enable, defaults portalPackage to xdg-desktop-portal-hyprland,
  # and adds the GTK portal via wayland-session.nix. Overriding portalPackage
  # with xdg-desktop-portal-wlr is what left the wlr portal running with no
  # config file, since xdg.portal.wlr (which generates it) stays disabled for
  # Hyprland.
  #
  # UWSM wraps the compositor in systemd units and starts
  # graphical-session.target once it is up, so user services bound to that
  # target start and stop with the session. zsh/default.nix launches it on tty1.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  programs.hyprlock.enable = true;
  services.hypridle.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
