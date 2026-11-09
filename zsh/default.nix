{
  lib,
  pkgs,
  username,
  ...
}: {
  users.users.${username}.shell = pkgs.zsh;

  programs = {
    zsh = {
      enable = true;
      setOptions = [
        "HIST_IGNORE_ALL_DUPS"
        "SHARE_HISTORY"
      ];
      syntaxHighlighting = {
        enable = true;
      };
      autosuggestions = {
        enable = true;
        strategy = ["history" "completion"];
        highlightStyle = "fg=245";
        extraConfig = {
          "ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE" = "20";
        };
      };
      loginShellInit = ''
        # Only on the tty1 console itself. `uwsm check may-start` alone is not
        # enough: it looks at the session's VT, so a login shell in a terminal
        # emulator of a session that was not started by UWSM also passes it and
        # would try to launch a second Hyprland.
        if [ -z "''${WAYLAND_DISPLAY:-}" ] && [ "$(tty)" = /dev/tty1 ] && uwsm check may-start; then
          exec uwsm start -e -D Hyprland hyprland.desktop
        fi
      '';
      shellInit = ''
        ZDOTDIR=~/.config/zsh
      '';
      # fzf picker for tab completion. It has to load after compinit and
      # before autosuggestions and syntax highlighting wrap the widgets.
      interactiveShellInit = lib.mkBefore ''
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '';
    };

    # The zsh hook is initialised in config/zsh/.zshrc after fzf, which would
    # otherwise take Ctrl-R back. Up-arrow keeps the vi-mode history search.
    atuin = {
      enable = true;
      enableZshIntegration = false;
      daemon.enable = false;
      settings = {
        enter_accept = false;
        style = "compact";
      };
    };

    bat.enable = true;
    yazi.enable = true;
  };
}
