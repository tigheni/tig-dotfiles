PROJECTS_DIR=~/Projects
REPO_LINK=$(wl-paste)
REPO_NAME=$(basename $REPO_LINK .git | tr . _)

git clone $REPO_LINK $PROJECTS_DIR/$REPO_NAME
tmux new-session -d -s $REPO_NAME -c $PROJECTS_DIR/$REPO_NAME
tmux switch-client -t $REPO_NAME
