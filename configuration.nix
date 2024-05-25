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
      spotify
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
      nodejs_21
      discord
      
  
    ];
  };
  home-manager.users.tig = {...}: {
    imports = [
      ./wezterm
      ./neovim
      ./tmux
      ./hyprland
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
  environment.systemPackages = [];

  # Configure keymap in X11
  # services.xserver = {
  # layout = "us";
  # xkbVariant = "";
  # };

  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true; # Enable networking

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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # system.autoUpgrade.enable = true;
  # system.autoUpgrade.allowReboot = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
