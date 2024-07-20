{...}: {
  home.username = "abdennour";
  home.homeDirectory = "/home/abdennour";

  imports = [
    ./wezterm
    ./neovim
    ./tmux
    ./starship
    ./lazygit
  ];

  home.file.".zshrc".text = "";

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      show-battery-percentage = true;
      text-scaling-factor = 1.25;
    };
    "org/gnome/desktop/input-sources" = {
      xkb-options = ["terminate:ctrl_alt_bksp" "lv3:ralt_switch" "caps:escape_shifted_capslock"];
    };
    "org/gnome/desktop/wm/keybindings" = {
      switch-input-source = ["XF86Keyboard"];
      switch-input-source-backward = ["<Shift>XF86Keyboard"];
      move-to-monitor-left = ["<Control><Super>h"];
      move-to-monitor-right = ["<Control><Super>l"];
      move-to-workspace-left = ["<Shift><Super>h"];
      move-to-workspace-right = ["<Shift><Super>l"];
      switch-to-workspace-left = ["<Super>h" "<Super>m"];
      switch-to-workspace-right = ["<Super>l" "<Super>i"];
      switch-windows = ["<Alt>Tab"];
      switch-windows-backward = ["<Shift><Alt>Tab"];
      switch-applications = ["<Super>Tab"];
      switch-applications-backward = ["<Shift><Super>Tab"];
      close = ["<Super>w"];
      maximize = ["<Super>o"];
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
      night-light-schedule-from = 18.0;
      night-light-schedule-to = 18.0;
      night-light-temperature = 2700;
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
      ];
    };
    "org/gnome/shell/keybindings" = {
      toggle-quick-settings = ["<Super>q"];
      toggle-message-tray = [];
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      control-center = ["<Super>s"];
      next = ["<Super>j"];
      previous = ["<Super>k"];
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
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Wezterm";
      command = "wezterm";
      binding = "<Super>t";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Spotify Play/Pause";
      command = "playerctl -p spotify play-pause";
      binding = "<Control><Alt>space";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "Spotify Next";
      command = "playerctl -p spotify next";
      binding = "<Control><Alt>j";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      name = "Spotify Previous";
      command = "playerctl -p spotify previous";
      binding = "<Control><Alt>k";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      name = "Turn off screen";
      command = "busctl --user call org.gnome.Shell /org/gnome/ScreenSaver org.gnome.ScreenSaver SetActive b true";
      binding = "<Control><Alt>z";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
      name = "Hubstaff";
      command = "/home/abdennour/Projects/dotfiles/scripts/toggle-hubstaff.sh";
      binding = "<Control><Alt>h";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6" = {
      name = "Both";
      command = "/home/abdennour/Projects/dotfiles/scripts/toggle-both.sh";
      binding = "<Control><Alt>b";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7" = {
      name = "Open clipboard manager";
      command = "copyq menu";
      binding = "<Super>v";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8" = {
      name = "Connect headphones";
      command = "bluetoothctl connect 14:3F:A6:22:76:4A";
      binding = "<Super>b";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9" = {
      name = "Brave Play/Pause";
      command = "playerctl -p brave play-pause";
      binding = "<Super>space";
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
