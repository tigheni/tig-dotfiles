{
  pkgs,
  pkgs-unstable,
  ...
}: let
  tmux-sessions-fzf = pkgs.writeShellScriptBin "s" (builtins.readFile ./tmux/tmux-sessions-fzf.sh);
  tmux-output-nvim = pkgs.writeShellScriptBin "tmux-output-nvim" (builtins.readFile ./tmux/tmux-output-nvim.sh);
  init-project = pkgs.writeShellScriptBin "init-project" (builtins.readFile ./tmux/init-project.sh);
in {
  users.users.tig.packages = with pkgs; [
    brave
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
    comma
    nurl
    bun
    qutebrowser
    google-chrome
    zotero
    htop
    bluetuith
    vscode
    wpsoffice
    wezterm
    (flameshot.override {enableWlrSupport = true;})
    (import ./packages/spotify.nix {inherit pkgs;})
    (mpv.override {scripts = with mpvScripts; [mpris mpv-cheatsheet-ng memo];})
    nodejs_24
    pkgs-unstable.code-cursor
    kdePackages.okular
    kdePackages.ghostwriter
    stirling-pdf

    # Hyprland and desktop tools
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
    bluez-tools
    obexftp
    kdePackages.kdeconnect-kde

    # Voxtype and its Wayland output/notification backends
    voxtype
    wtype
    libnotify

    # Neovim language servers and formatters
    gcc
    gnumake
    pyright
    lua-language-server
    vscode-langservers-extracted
    tailwindcss-language-server
    yaml-language-server
    alejandra
    stylua
    nixd
    emmet-language-server
    prettierd
    taplo
    vtsls
    gopls
    golangci-lint
    typos-lsp
    hyprls
    lynx

    # Tmux helpers
    tmux-sessions-fzf
    tmux-output-nvim
    init-project
  ];
}
