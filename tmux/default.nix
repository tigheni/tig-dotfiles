{pkgs, ...}: let
  tmux-sessionizer = pkgs.writeShellScriptBin "s" (builtins.readFile ./tmux-sessionizer.sh);
in {
  programs.tmux = {
    enable = true;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;

    extraConfig = ''
      unbind C-b
      set -g prefix M-\;
      bind -n M-\; send-prefix

      bind r source-file ~/.config/tmux/tmux.conf

      set -g status off
      # set-window-option -g mode-keys vi

      bind l split-window -h
      bind j split-window -v
      bind -r m resize-pane -Z

      bind i split-window -h
      bind n split-window -v


      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
      | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

      bind -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U ; resize-pane -Z'
      bind -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'

      bind -n 'M-m' if-shell "$is_vim" 'send-keys M-m'  'select-pane -L'
      bind -n 'M-n' if-shell "$is_vim" 'send-keys M-n'  'select-pane -D'
      bind -n 'M-e' if-shell "$is_vim" 'send-keys M-e'  'select-pane -U ; resize-pane -Z'
      bind -n 'M-i' if-shell "$is_vim" 'send-keys M-i'  'select-pane -R'

      bind s display-popup -E "s"
      bind k switch-client -n
      bind e switch-client -n

      bind -T copy-mode-vi i switch-client -T copyModeMultiKey_i
      bind -T copyModeMultiKey_i w send-keys -X select-word
      bind -T copyModeMultiKey_i W send-keys -X clear-selection \; send-keys -X previous-space \; send-keys -X begin-selection \; send-keys -X next-space-end
      bind -T copyModeMultiKey_i b send-keys -X clear-selection \; send-keys -X jump-to-backward '(' \; send-keys -X begin-selection \; send-keys -X jump-to-forward ')'
      bind -T copyModeMultiKey_i ( send-keys -X clear-selection \; send-keys -X jump-to-backward '(' \; send-keys -X begin-selection \; send-keys -X jump-to-forward ')'
      bind -T copyModeMultiKey_i ) send-keys -X clear-selection \; send-keys -X jump-to-backward '(' \; send-keys -X begin-selection \; send-keys -X jump-to-forward ')'
      bind -T copyModeMultiKey_i B send-keys -X clear-selection \; send-keys -X jump-to-backward '{' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '}'
      bind -T copyModeMultiKey_i \{ send-keys -X clear-selection \; send-keys -X jump-to-backward '{' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '}'
      bind -T copyModeMultiKey_i \} send-keys -X clear-selection \; send-keys -X jump-to-backward '{' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '}'
      bind -T copyModeMultiKey_i [ send-keys -X clear-selection \; send-keys -X jump-to-backward '[' \; send-keys -X begin-selection \; send-keys -X jump-to-forward ']'
      bind -T copyModeMultiKey_i ] send-keys -X clear-selection \; send-keys -X jump-to-backward '[' \; send-keys -X begin-selection \; send-keys -X jump-to-forward ']'
      bind -T copyModeMultiKey_i < send-keys -X clear-selection \; send-keys -X jump-to-backward '<' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '>'
      bind -T copyModeMultiKey_i > send-keys -X clear-selection \; send-keys -X jump-to-backward '<' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '>'
      bind -T copyModeMultiKey_i ` send-keys -X clear-selection \; send-keys -X jump-to-backward '`' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '`'
      bind -T copyModeMultiKey_i \' send-keys -X clear-selection \; send-keys -X jump-to-backward "'" \; send-keys -X begin-selection \; send-keys -X jump-to-forward "'"
      bind -T copyModeMultiKey_i \" send-keys -X clear-selection \; send-keys -X jump-to-backward '"' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '"'
      bind -T copyModeMultiKey_i l send-keys -X clear-selection \; send-keys -X back-to-indentation \; send-keys -X begin-selection \; send-keys -X end-of-line \; send-keys -X cursor-left \; send-keys -X other-end

      set -ga terminal-overrides ',xterm-256color:Tc'
    '';
  };

  home.packages = [
    tmux-sessionizer
  ];
}
