file=`mktemp`.sh
tmux capture-pane -p > $file
tmux new-window "nvim '+ normal G $' $file"
