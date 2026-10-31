#!/usr/bin/env bash

file=$(mktemp --suffix=.sh)
tmux capture-pane -p -S - > "$file"
tmux new-window "nvim '+ normal G $' '$file'; rm -f '$file'"
