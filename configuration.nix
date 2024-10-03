{pkgs, ...}: {
  nixpkgs.overlays = map (n: (import ./overlays/${n})) (builtins.attrNames (builtins.readDir ./overlays));
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    warn-dirty = false;
  };
  imports = [
    ./hardware-configuration.nix
    ./zsh
  ];
  nixpkgs.config.allowUnfree = true;

  hardware.graphics.extraPackages = with pkgs; [
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
  users.users.abdennour = {
    isNormalUser = true;
    description = "Abdennour Zahaf";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
      brave
      spotify
      xsel
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
      delta
      hubstaff
      protonvpn-gui
      zip
      unzip
      tldr
      glab
      comma
      (import ./scripts/npg.nix {inherit pkgs;})
      epiphany
    ];
  };

  services.playerctld.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 3";
    flake = "/home/abdennour/Projects/dotfiles";
  };

  specialisation = {
    gnome.configuration = import ./gnome;
    hyprland.configuration = import ./hyprland;
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
