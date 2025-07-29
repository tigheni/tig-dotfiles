{pkgs, ...}: let
  tmux-sessions-fzf = pkgs.writeShellScriptBin "s" (builtins.readFile ./tmux-sessions-fzf.sh);
  tmux-output-nvim = pkgs.writeShellScriptBin "tmux-output-nvim" (builtins.readFile ./tmux-output-nvim.sh);
  init-project = pkgs.writeShellScriptBin "init-project" (builtins.readFile ./init-project.sh);
in {
  programs.tmux.enable = true;

  users.users.tig.packages = [
    tmux-sessions-fzf
    tmux-output-nvim
    init-project
  ];
}
