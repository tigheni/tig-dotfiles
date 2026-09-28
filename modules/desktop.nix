_: {
  services = {
    # Removable media and trash support for the file manager.
    gvfs.enable = true;
    devmon.enable = true;
    udisks2.enable = true;

    # Backs the `power-profiles-daemon` entry in config/waybar/config.jsonc,
    # which was previously rendering against a daemon that never ran.
    power-profiles-daemon.enable = true;

    # Secret Service provider. Without one, Brave/VSCode/Cursor fall back to
    # plaintext credential storage.
    gnome.gnome-keyring.enable = true;
  };

  # The Hyprland session starts from a TTY login, so that is where the keyring
  # has to be unlocked.
  security.pam.services.login.enableGnomeKeyring = true;
}
