{
  pkgs,
  config,
  ...
}: {
nixpkgs.overlays = map (n: (import ./overlays/${n})) (builtins.attrNames (builtins.readDir ./overlays));
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=${config.users.users.tig.home}/dotfiles/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  imports = [
    /etc/nixos/hardware-configuration.nix
    <home-manager/nixos>
    ./gnome
    ./zsh
  ];
  nixpkgs.config.allowUnfree = true;

  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  nix.optimise.automatic = true;
  time.timeZone = "Africa/Algiers";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tig = {
    isNormalUser = true;
    description = "tig";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
      gcc
      gnumake
      vscode
      google-chrome
      firefox-devedition
      protonvpn-gui
      kitty
      xsel
      neofetch
      gh
      ripgrep
      fd
      jq
      webtorrent_desktop
      vlc
      ytarchive
      ffmpeg
      zoxide
      fzf
      bat
      delta
      brave
      copyq
      stremio
      discord
      nodejs_22
      spotify
      pavucontrol
      kdenlive
      playerctl
    ];
  };
  home-manager.users.tig = {...}: {
    imports = [
      ./wezterm
      ./neovim
      ./tmux
    /*   ./hyprland */
      ./starship
    ];

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "23.11";
  };

  programs.git = {
    enable = true;
    config = {
      user = {
        name = "tigheni";
        email = "oussama.adame12@gmail.com";
      };
    };
    prompt = {
      enable = true;
    };
  };

  programs.direnv = {
    enable = true;
    silent = true;
  };



  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];



 networking.firewall.enable = true;

  # Custom firewall rules
  # networking.firewall.extraCommands = ''
  # iptables -I nixos-fw 1 -p tcp --dport 1716 -j ACCEPT
  # iptables -I nixos-fw 1 -p udp --dport 1716 -j ACCEPT
  # iptables -I nixos-fw 1 -p tcp --dport 1739 -j ACCEPT
  # iptables -I nixos-fw 1 -p udp --dport 1764 -j ACCEPT
  # iptables -I nixos-fw 1 -m mac --mac-source 44:8a:5b:95:50:f8 -j ACCEPT
  #'';


 networking.firewall.allowedTCPPortRanges = [
  { from = 1714; to = 1764; }
];
networking.firewall.allowedUDPPortRanges = [
  { from = 1714; to = 1764; }
];

  # systemd.user.timers."numlockx_boot" = {
  #   wantedBy = ["timers.target"];
  #   timerConfig = {
  #     OnStartupSec = "1us";
  #     AccuracySec = "1us";
  #     Unit = "numlockx.service";
  #   };
  # };

  # systemd.user.timers."numlockx_sleep" = {
  #   wantedBy = [
  #     "suspend.target"
  #     "hibernate.target"
  #     "hybrid-sleep.target"
  #     "suspend-then-hibernate.target"
  #   ];
  #   after = [
  #     "suspend.target"
  #     "hibernate.target"
  #     "hybrid-sleep.target"
  #     "suspend-then-hibernate.target"
  #   ];
  #   timerConfig = {
  #     AccuracySec = "1us";
  #     Unit = "numlockx.service";
  #   };
  # };

  # systemd.user.services."numlockx" = {
  #   script = ''
  #     ${pkgs.numlockx}/bin/numlockx on
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot"; # "simple" für Prozesse, die weiterlaufen sollen
  #   };
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget



  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.displayManager.sddm.wayland.enable = true;
  # services.xserver.displayManager.sddm.theme = "where_is_my_sddm_theme";
  # services.xserver.displayManager.autoLogin.enable = true;
  # services.xserver.displayManager.autoLogin.user = "abdennour";

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;
  # nixpkgs.config.pulseaudio = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # system.autoUpgrade.enable = true;
  # system.autoUpgrade.allowReboot = true;
  system.stateVersion = "23.11"; # Did you read the comment?
}