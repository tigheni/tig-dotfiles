{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    # Save and restore sessions across reboots: prefix + Ctrl-s saves,
    # prefix + Ctrl-r restores. tmux-continuum is left out on purpose: its
    # autosave hooks into the status line, which config/tmux/tmux.conf hides.
    plugins = [pkgs.tmuxPlugins.resurrect];
  };
}
