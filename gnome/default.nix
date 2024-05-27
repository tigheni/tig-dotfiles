{pkgs, ...}: {
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  services.xserver.xkbOptions = "terminate:ctrl_alt_bksp, lv3:ralt_switch, caps:escape_shifted_capslock";

  services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];
  programs.dconf.enable = true;

  users.users.tig = {
    packages = with pkgs; [
      gnome.gnome-tweaks
      gnome.gnome-shell
      gnome.gnome-shell-extensions
      gnomeExtensions.appindicator
      gnomeExtensions.vitals
      gnomeExtensions.hide-minimized
      gnomeExtensions.notification-timeout
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.blur-my-shell
      gnomeExtensions.dash-to-dock
      gnome.dconf-editor
      gnomeExtensions.gsconnect
     
    ];
  };

  # ln -s /dev/null ~/Pictures/Screenshots
  system.userActivationScripts.linktosharedfolder.text = ''
    if [[ ! -h "$HOME/Pictures/Screenshots" ]]; then
      ln -s /dev/null  "$HOME/Pictures/Screenshots"
    fi
  '';

  home-manager.users.tig = {
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        enable-hot-corners = false;
        show-battery-percentage = false;
        text-scaling-factor = 1.0;
      };
      "org/gnome/desktop/input-sources" = {
        xkb-options = ["terminate:ctrl_alt_bksp" "lv3:ralt_switch" "caps:escape_shifted_capslock"];
        show-all-sources = false;
      };
      "org/gnome/desktop/wm/keybindings" = {
        switch-input-source = ["XF86Keyboard"];
        switch-input-source-backward = ["<Shift>XF86Keyboard"];
        move-to-monitor-left = ["<Control><Super>h"];
        move-to-monitor-right = ["<Control><Super>l"];
        move-to-workspace-left = ["<Shift><Super>h"];
        move-to-workspace-right = ["<Shift><Super>l"];
        switch-to-workspace-left = ["<Super>h"];
        switch-to-workspace-right = ["<Super>l"];
        switch-windows = ["<Alt>Tab"];
        switch-windows-backward = ["<Shift><Alt>Tab"];
        switch-applications = ["<Super>Tab"];
        switch-applications-backward = ["<Shift><Super>Tab"];
        #   activate-window-menu = "disabled";
        #   close = ["<Super>q"];
        maximize = ["<Super>m"];
        minimize = ["<Super>comma"];
        #   move-to-monitor-down = "disabled";
        #   move-to-monitor-left = "disabled";
        #   move-to-monitor-right = "disabled";
        #   move-to-monitor-up = "disabled";
        #   move-to-workspace-down = "disabled";
        #   move-to-workspace-up = "disabled";
        #   toggle-maximized = ["<Super>m"]';
        #   unmaximize = "disabled";
      };
      "org/gnome/desktop/peripherals/keyboard" = {
        numlock-state = true;
      };
      "org/gnome/mutter" = {
        dynamic-workspaces = true;
      };
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
        two-finger-scrolling-enabled = true;
      };
      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-automatic = false;
        night-light-schedule-from = 20.0;
        night-light-schedule-to = 7.0;
        night-light-temperature = 2500;
      };
      "ca/desrt/dconf-editor" = {
        show-warning = false;
      };
      "org/gnome/shell" = {
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "Vitals@CoreCoding.com"
          "hide-minimized@danigm.net"
          "notification-timeout@chlumskyvaclav.gmail.com"
          "blur-my-shell@aunetx"
          "clipboard-indicator@tudmotu.com"
          "dash-to-dock@micxgx.gmail.com"
          "gsconnect@andyholmes.github.io"
        ];
      };
      "org/gnome/shell/keybindings" = {
        toggle-quick-settings = [];
        toggle-message-tray = [];
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        control-center = ["<Super>s"];
        play = ["<Super>space"];
        next = ["<Super>j"];
        previous = ["<Super>k"];
        # playback-rewind = ["<Ctrl><Alt>h"];
        # playback-forward = ["<Ctrl><Alt>l"];
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Wezterm";
        command = "wezterm";
        binding = "<Super>t";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Toggle";
        command = "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause";
        binding = "<Control>space";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name = "Next";
        command = "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next";
        binding = "<Control><Alt>j";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        name = "Previous";
        command = "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous";
        binding = "<Control><Alt>k";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
        name = "Turn off screen";
        command = "busctl --user call org.gnome.Shell /org/gnome/ScreenSaver org.gnome.ScreenSaver SetActive b true";
        binding = "<Control><Alt>z";
      }; 
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
        name = "toggle audio output ";
        command = "/home/tig/dotfiles/scripts/audio_Output_changer.sh";
        binding = "<Control><Alt>p";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6" = {
        name = "suspend ";
        command = "systemctl suspend";
        binding = "<Control><super>s";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7" = {
        name = "Turn off pc";
        command = "systemctl poweroff";
        binding = "<Control><super>d";
      };
       "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8" = {
        name = "spotify";
        command = "LD_PRELOAD=/home/tig/Downloads/spotify-adblock.so spotify";
        binding = "<Control><super>w";
      };
    };
  };
}