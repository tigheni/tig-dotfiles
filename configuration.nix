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
boot.loader = {
  grub = {
    enable = true;
    efiSupport = true;           # Enable UEFI support
    efiInstallAsRemovable = false;
    device = "nodev";            # Don't specify a device for UEFI
    useOSProber = true;          # This will detect Windows
    #configurationLimit = 10;     # Keep last 10 NixOS generations in menu
  };
  efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";   # Make sure this matches where your EFI partition is mounted
  };
};
  # bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };
  services.blueman.enable = true;

  networking.hostName = "nixos";

  # Enable networking
  networking.networkmanager.enable = true;



  # Enable the X11 windowing system.
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "symbolic";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

  };
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  users.users.tig = {
    isNormalUser = true;
    description = "tig";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
        google-chrome
        vscode
        brave
        protonvpn-gui
        fzf
        zoxide
        fd
        playerctl
        nodejs_20
        bat
        stremio
        discord
        gh
        ripgrep
        jq
        ffmpeg
        delta
        protonvpn-gui
        gnumake
        tldr
        glab
        comma
        nurl
        epiphany
        joplin-desktop
        os-prober
        blanket
        libreoffice
        spotify
    ];
  };

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

systemd.services.bluetooth-modprobe = {
  description = "Reload btusb module at boot";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStartPre = "/run/current-system/sw/bin/bash -c '/run/current-system/sw/bin/modprobe -r btusb'";  # Correct path to modprobe
    ExecStart = "/run/current-system/sw/bin/bash -c '/run/current-system/sw/bin/modprobe -v btusb'";  # Correct path to modprobe
  };
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
 ACTION=="add" SUBSYSTEM=="pci" ATTR{vendor}=="0x1022" ATTR{device}=="0x1639" ATTR{power/wakeup}="disabled"
 ACTION=="add" SUBSYSTEM=="pci" ATTR{vendor}=="0x1022" ATTR{device}=="0x43d5" ATTR{power/wakeup}="disabled"
'';
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [];

  # Open ports in the firewall.
    networking.firewall.allowedTCPPortRanges = [
  { from = 1714; to = 1764; }
];
networking.firewall.allowedUDPPortRanges = [
  { from = 1714; to = 1764; }
];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
