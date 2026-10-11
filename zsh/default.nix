{
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
        if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
          exec start-hyprland
        fi
      '';
      shellInit = ''
        ZDOTDIR=~/.config/zsh
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
