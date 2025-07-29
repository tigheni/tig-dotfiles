tmux start-server

selected="$(fd . "$HOME"/tig-dotfiles --min-depth 1 --maxdepth 1 --type d --format {/} | fzf --bind=enter:replace-query+print-query)"

if [[ -z $selected ]]; then
    exit 0
fi

selected="$HOME/tig-dotfiles/$selected"

if [ ! -d $selected ]; then
    mkdir $selected
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2> /dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

if [ -z "$TMUX" ]; then
    tmux attach -t "$selected_name"
else
    tmux switch-client -t "$selected_name"
fi
