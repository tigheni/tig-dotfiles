{pkgs, ...}: {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    warn-dirty = false;
  };
  imports = [
    ./hardware-configuration.nix
    ./zsh
    ./hyprland
    ./neovim
    ./tmux
    ./whitelist
  ];
  nixpkgs.config.allowUnfree = true;

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
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
      (pkgs.symlinkJoin {
        name = "vlc";
        paths = [pkgs.vlc];
        buildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/vlc \
            --unset DISPLAY
          mv $out/share/applications/vlc.desktop{,.orig}
          substitute $out/share/applications/vlc.desktop{.orig,} \
            --replace-fail Exec=${pkgs.vlc}/bin/vlc Exec=$out/bin/vlc
        '';
      })
      brave
      gh
      ripgrep
      fd
      jq
      ytarchive
      ffmpeg
      zoxide
      fzf
      delta
      zip
      unzip
      tldr
      glab
      comma
      nurl
      epiphany
      htop
      bluetuith
      ddcutil
      batsignal
      kanshi
      kitty
      (flameshot.override {enableWlrSupport = true;})
      (import ./packages/spotify.nix {pkgs = pkgs;})
    ];
  };

  programs.starship.enable = true;
  programs.waybar.enable = true;

  programs.git = {
    enable = true;
    config = {
      user = {
        name = "Abdennour Zahaf";
        email = "zfnori@gmail.com";
      };
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };
  services.playerctld.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 3";
    flake = "/home/abdennour/Projects/dotfiles";
  };

  programs.direnv = {
    enable = true;
    silent = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = [];

  system.userActivationScripts.dotfiles = builtins.readFile ./scripts/symlink-config.sh;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
