# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
    nixpkgs.overlays = map (n: (import ./overlays/${n})) (builtins.attrNames (builtins.readDir ./overlays));
    nix.settings.experimental-features = ["nix-command" "flakes"];
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./gnome
      ./zsh
    ];

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "/dev/sdb"; # Install GRUB to /dev/sdb
    useOSProber = true;  # Detect other OSes (Windows)

  };


  boot.loader.efi.canTouchEfiVariables = true;


  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.



  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "symbolic";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tig = {
    isNormalUser = true;
    description = "tig";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
        google-chrome
        vscode
        brave
        spotify
        protonvpn-gui
        vlc
        fzf
        zoxide
        fd
        playerctl
        nodejs_22
        bat
        stremio
        discord
        gh
        ripgrep
        jq
        ffmpeg
        delta
        protonvpn-gui
        zip
        unzip
        tldr
        glab
        comma
        nurl
        epiphany
        pavucontrol

    ];
  };



  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 3";
    flake = "/home/tig/tig-dotfiles";
  };

  programs.direnv = {
    enable = true;
    silent = true;
  };
services.udev.extraRules = ''
SUBSYSTEM=="input", ATTRS{name}=="SZH usb keyboard", ATTR{power/wakeup}="disabled"
'';
  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono" "Iosevka" ];})
  ];
  # Enable automatic login for the user.
  #services.xserver.displayManager.autoLogin.enable = true;
  #services.displayManager.autoLogin ="tig";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  #systemd.services."getty@tty1".enable = false;
  #systemd.services."autovt@tty1".enable = false;

  # Install firefox.
  #programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

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
    networking.firewall.allowedTCPPortRanges = [
  { from = 1714; to = 1764; }
];
networking.firewall.allowedUDPPortRanges = [
  { from = 1714; to = 1764; }
];
networking.firewall.allowedTCPPorts = [ 59010 ];
networking.firewall.allowedUDPPorts = [ 59010 ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
