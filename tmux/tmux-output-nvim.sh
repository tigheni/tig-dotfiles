#!/usr/bin/env bash

file=$(mktemp).sh
tmux capture-pane -p -S - > "$file"
tmux new-window "nvim '+ normal G $' $file"
