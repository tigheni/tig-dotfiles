{...}: {
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;

    extraConfig = ''
      unbind C-b
      set -g prefix M-\;
      bind -n M-\; send-prefix

      bind r source-file /etc/tmux.conf

      set -g status off
      # set-window-option -g mode-keys vi

      bind l split-window -h
      bind j split-window -v

      bind -r m resize-pane -Z

      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
      | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
      bind -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U ; resize-pane -Z'
      bind -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
    '';
  };
}
