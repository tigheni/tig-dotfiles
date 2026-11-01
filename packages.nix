{
  pkgs,
  pkgs-unstable,
  username,
  llm-agents,
  ...
}: let
  tmux-sessions-fzf = pkgs.writeShellScriptBin "s" (builtins.readFile ./tmux/tmux-sessions-fzf.sh);
  tmux-output-nvim = pkgs.writeShellScriptBin "tmux-output-nvim" (builtins.readFile ./tmux/tmux-output-nvim.sh);
  init-project = pkgs.writeShellScriptBin "init-project" (builtins.readFile ./tmux/init-project.sh);
in {
  users.users.${username}.packages =
    (with pkgs; [
      brave
      telegram-desktop
      gh
      ripgrep
      fd
      jq
      ffmpeg
      zoxide
      fzf
      delta
      zip
      unzip
      tldr
      eza
      dust
      lazydocker
      pgcli
      nurl
      bun
      qutebrowser
      google-chrome
      zotero
      btop
      bluetuith
      vscode
      wpsoffice
      wezterm
      (flameshot.override {enableWlrSupport = true;})
      (import ./packages/spotify.nix {inherit pkgs;})
      (mpv.override {scripts = with mpvScripts; [mpris mpv-cheatsheet-ng memo];})
      nodejs_24
      pnpm
      pkgs-unstable.code-cursor
      kdePackages.ghostwriter
      matugen
      libnotify
      discord
      lynx

      # Hyprland and desktop tools
      wl-clipboard
      wl-gammarelay-rs
      rofi
      grim
      hyprpicker
      hyprpaper
      nautilus
      bibata-cursors
      networkmanagerapplet
      pavucontrol
      # ArchEclipse shell (config/quickshell/archeclipse, scripts/archeclipse.sh)
      (import ./packages/quickshell.nix {inherit pkgs;})

      # ArchEclipse Quickshell config (config/quickshell/archeclipse)
      (python3.withPackages (ps: with ps; [requests])) # launcher app list, wallhaven
      zenity # wallpaper import picker
      pulseaudio # pactl for the control panel volume section; PipeWire stays the server
      bc # launcher calculator
      translate-shell
      (import ./packages/archeclipse-sysmonitor.nix {inherit pkgs;})

      # Voxtype voice-to-text and its Wayland typing backend
      voxtype-vulkan
      wtype

      bluez-tools
      obexftp
      kdePackages.kdeconnect-kde

      # Tmux helpers
      tmux-sessions-fzf
      tmux-output-nvim
      init-project
    ])
    ++ (with llm-agents; [
      claude-code
      codex
    ]);
}
