{pkgs, ...}: {
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

  # Password prompts for apps that ask polkit for admin rights. Its user unit
  # is started from Hyprland's autostart, after the Wayland variables are
  # imported.
  systemd.packages = [pkgs.hyprpolkitagent];
}
