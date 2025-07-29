{pkgs, ...}: {
  users.users.tig.shell = pkgs.zsh;

  programs.zsh = {
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
        exec Hyprland
      fi
    '';
    shellInit = ''
      ZDOTDIR=~/.config/zsh
    '';
  };
}
