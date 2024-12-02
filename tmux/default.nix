{
  config,
  pkgs,
  ...
}: let
  tmux-sessionizer = pkgs.writeShellScriptBin "s" (builtins.readFile ./tmux-sessionizer.sh);
  tmux-output-nvim = pkgs.writeShellScriptBin "tmux-output-nvim" (builtins.readFile ./tmux-output-nvim.sh);
in {
  programs.tmux.enable = true;
  home.packages = [
    tmux-sessionizer
    tmux-output-nvim
  ];
  xdg.configFile."tmux/tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/tmux/tmux.conf";
}
