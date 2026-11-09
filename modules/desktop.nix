{
  pkgs,
  username,
  ...
}: let
  flameshot = pkgs.flameshot.override {enableWlrSupport = true;};

  # A daemon that lives and dies with the Hyprland session. UWSM starts
  # graphical-session.target only after the compositor has exported
  # WAYLAND_DISPLAY to systemd, so these never start without a display.
  sessionService = description: command: {
    inherit description;
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];
    # The user's normal PATH instead of the minimal systemd one, so links and
    # files these daemons open (xdg-open, the browser) can be found.
    path = ["/run/wrappers" "/etc/profiles/per-user/${username}" "/run/current-system/sw"];
    serviceConfig = {
      ExecStart = command;
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
in {
  services = {
    # Removable media and trash support for the file manager.
    gvfs.enable = true;
    devmon.enable = true;
    udisks2.enable = true;

    # Secret Service provider. Without one, Brave/VSCode/Cursor fall back to
    # plaintext credential storage.
    gnome.gnome-keyring.enable = true;
  };

  # The Hyprland session starts from a TTY login, so that is where the keyring
  # has to be unlocked.
  security.pam.services.login.enableGnomeKeyring = true;

  # Password prompts for apps that ask polkit for admin rights. The package
  # ships the unit; NixOS ignores its [Install] section, hence the wantedBy.
  systemd.packages = [pkgs.hyprpolkitagent];

  systemd.user.services = {
    hyprpolkitagent.wantedBy = ["graphical-session.target"];

    # D-Bus relay that scripts/night-light.sh sets the screen temperature through.
    wl-gammarelay-rs = sessionService "Screen temperature relay" "${pkgs.wl-gammarelay-rs}/bin/wl-gammarelay-rs";

    # Screenshot daemon behind `flameshot gui` and the ArchEclipse capture.
    flameshot = sessionService "Flameshot screenshot daemon" "${flameshot}/bin/flameshot";

    kdeconnectd = sessionService "KDE Connect daemon" "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnectd";
    kdeconnect-indicator =
      sessionService "KDE Connect tray indicator" "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
      // {after = ["graphical-session.target" "kdeconnectd.service"];};
  };

  environment.systemPackages = [flameshot];

  # Installs KDE Connect and opens its firewall ports (1714-1764 TCP/UDP).
  programs.kdeconnect.enable = true;

  # Screen recording for ArchEclipse (scripts/screenrecord.sh). The setcap
  # wrapper on gsr-kms-server lets it capture a monitor without a portal prompt.
  programs.gpu-screen-recorder.enable = true;
}
