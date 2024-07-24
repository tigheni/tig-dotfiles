{pkgs, ...}: {
  services.xserver = {
  enable = true;
  displayManager.gdm.enable = true;
  desktopManager.gnome.enable = true;
 xkb.options = "terminate:ctrl_alt_bksp, lv3:ralt_switch, caps:escape_shifted_capslock";
};
  services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];
  programs.dconf.enable = true;
  users.users.tig = {
    packages = with pkgs; [
      gnome.gnome-tweaks
      gnomeExtensions.gsconnect
      gnome.dconf-editor
      gnomeExtensions.vitals
      gnomeExtensions.notification-timeout
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.blur-my-shell
      gnomeExtensions.dash-to-dock
      gnomeExtensions.hide-keyboard-layout
      gnome46Extensions."openweather-extension@penguin-teal.github.io"
    ];
  };

  environment.gnome.excludePackages = (with pkgs; [
  gnome-tour
]) ++ (with pkgs.gnome; [
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

  home-manager.users.tig = {
    dconf = {
      settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        enable-hot-corners = false;
        show-battery-percentage = false;
        text-scaling-factor = 1.0;
      };
      "org/gnome/desktop/input-sources" = {
        show-all-sources = true;
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
        toggle-maximized = ["<Super>m"]';
      };
      "org/gnome/desktop/peripherals/keyboard" = {
        numlock-state = true;
      };
      "org/gnome/mutter" = {
        dynamic-workspaces = true;
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
          "hide-keyboard-layout@sitnik.ru"
          "openweather-extension@penguin-teal.github.io"

        ];
      };
      "org/gnome/shell/keybindings" = {
        toggle-quick-settings = [];
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
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Wezterm";
        command = "wezterm";
        binding = "<Super>t";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Toggle";
        command = "playerctl -p spotify play-pause";
        binding = "<Control>space";
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
        name="toggle chrome player";
        command="playerctl -p chromium play-pause";
        binding="<Control><super>space";

      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        name="position changer";
        command="playerctl position 20+";
        binding="<Control><Alt>h";

      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name="position changer";
        command="playerctl position 20-";
        binding="<Control><alt>l";
      };

    };
  };
};
}