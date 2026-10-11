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
      comma
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
      # Waybar is started by scripts/waybar-launch.sh, not a systemd unit.
      waybar
      mako
      wl-clipboard
      wl-gammarelay-rs
      rofi
      clipse
      grim
      hyprpicker
      hyprpaper
      nautilus
      bibata-cursors
      networkmanagerapplet
      pavucontrol
      wttrbar

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
