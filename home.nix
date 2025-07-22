{lib, ...}: let
  keybindings = [
    {
      name = "Wezterm";
      command = "wezterm";
      binding = "<Super>t";
    }
    {
      name = "Media Play/Pause brave";
      command = "playerctl -p brave play-pause";
      binding = "<control><Super>space";
    }
    {
      name = "Media Play/Pause spotify";
      command = "playerctl -p spotify play-pause";
      binding = "<control>space";
    }
    {
      name = "Skip backward";
      command = "playerctl position 5-";
      binding = "<Control><Super>]";
    }
    {
      name = "Skip forward";
      command = "playerctl position 5+";
      binding = "<Control><Super>[";
    }
    {
      name = "suspend ";
      command = "systemctl suspend";
      binding = "<Control><super>s";
    }
    {
      name = "Turn off pc";
      command = "systemctl poweroff";
      binding = "<Control><super>d";
    }
    {
      name = "audio output switch";
      command = "tig-dotfiles/scripts/audio_Output_changer.sh";
      binding = "<Control><Alt>p";
    }
    {
      name = "headphones connect";
      command = "bluetoothctl connect 04:58:84:15:EE:9E";
      binding = "<super>b";
    }
  ];

  customPrefix = "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings";

  customKeybindingsPaths =
    map
    (sh: "/${customPrefix}/${sh.name}/")
    keybindings;

  customKeybindings = lib.listToAttrs (map
    (sh: {
      name = "${customPrefix}/${sh.name}";
      value = sh;
    })
    keybindings);
in {
  home.username = "tig";
  home.homeDirectory = "/home/tig";

  imports = [
    ./lazygit
    ./git
    ./neovim
    ./tmux
    ./starship
    ./wezterm
  ];

  dconf.settings =
    {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        enable-hot-corners = false;
        show-battery-percentage = true;
        text-scaling-factor = 1.0;
      };
      "org/gnome/desktop/input-sources" = {
        xkb-options = ["terminate:ctrl_alt_bksp" "lv3:ralt_switch" "caps:escape_shifted_capslock"];
      };
      "org/gnome/desktop/wm/keybindings" = {
        switch-input-source = ["<Super>space"];
        switch-input-source-backward = ["<Shift><Super>space"];
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
        maximize = ["<Super>m"];
        minimize = ["<Super>comma"];

        toggle-maximized = ["<Super>m"];
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
        night-light-schedule-to = 7.0;
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
          "blur-my-shell@aunetx"
          "clipboard-indicator@tudmotu.com"
          "dash-to-dock@micxgx.gmail.com"
          "gsconnect@andyholmes.github.io"
          "hide-keyboard-layout@sitnik.ru"
          "openweather-extension@penguin-teal.github.io"
          "no-titlebar-when-maximized@alec.ninja"
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
        custom-keybindings = customKeybindingsPaths;
      };
    }
    // customKeybindings;

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

