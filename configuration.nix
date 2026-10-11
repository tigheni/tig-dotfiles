{
  config,
  pkgs,
  username,
  dotfilesDir,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    ./modules/audio.nix
    ./modules/bluetooth.nix
    ./modules/desktop.nix
    ./modules/networking.nix
    ./zsh
    ./hyprland
    ./neovim
    ./tmux
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    warn-dirty = false;

    # llm-agents.nix (claude-code, codex) is not in cache.nixos.org, and its own
    # nixConfig does not propagate to us as an input — without this, every
    # flake.lock bump recompiles codex from source.
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
    auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = false;
        device = "nodev";
        useOSProber = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    tmp.cleanOnBoot = true;
  };

  zramSwap.enable = true;

  # Rootless only. The rootful daemon is dead weight once DOCKER_HOST points at
  # the per-user socket, and the `docker` group it requires is root-equivalent.
  virtualisation.docker = {
    enable = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  time.timeZone = "Africa/Algiers";
  environment.sessionVariables.DOTFILES_DIR = dotfilesDir;
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
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel" "input"];
  };

  programs = {
    starship.enable = true;
    git = {
      enable = true;
      config = {
        user = {
          name = "tigheni";
          email = "oussama.adame12@gmail.com";
        };
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d --keep 3";
      flake = dotfilesDir;
    };
    direnv = {
      enable = true;
      silent = true;
    };
  };

  services = {
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
    # udev requires comma-separated key/value tokens; without them `udevadm
    # verify` rejects the rule.
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x1639", ATTR{power/wakeup}="disabled"
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x43d5", ATTR{power/wakeup}="disabled"
    '';
    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      # Peer authentication: `psql` as ${username} works without a password.
      # ensureDBOwnership asserts a same-named database exists.
      ensureDatabases = [username];
      ensureUsers = [
        {
          name = username;
          ensureDBOwnership = true;
        }
      ];
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  system.userActivationScripts.tig-dotfiles =
    builtins.replaceStrings
    ["@DOTFILES_DIR@" "@CONFIG_DIR@"]
    [dotfilesDir "${config.users.users.${username}.home}/.config"]
    (builtins.readFile ./scripts/symlink-config.sh);

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
