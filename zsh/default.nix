{pkgs, ...}: {
  users.users.abdennour = {
    shell = pkgs.zsh;
  };

  home-manager.users.abdennour = {config, ...}: {
    home.file.".zshrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/zsh/.zshrc";
  };

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
    promptInit = "eval \"$(starship init zsh)\"";
    loginShellInit = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland
      fi
    '';
  };
}
