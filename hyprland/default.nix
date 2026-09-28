_: {
  # Nothing else belongs here. The Hyprland module already sets
  # xdg.portal.enable, defaults portalPackage to xdg-desktop-portal-hyprland,
  # and adds the GTK portal via wayland-session.nix. Overriding portalPackage
  # with xdg-desktop-portal-wlr is what left the wlr portal running with no
  # config file, since xdg.portal.wlr (which generates it) stays disabled for
  # Hyprland.
  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
