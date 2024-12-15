# Check if git aliases or abbrs are better
alias gaa="git add --all"
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend --no-edit"
alias gaca="gaa && gca"
alias gph="git push"
alias gpl="git pull"
alias grp="git reset HEAD~1"
alias grhh="git reset HEAD --hard && git clean -fd"
alias glo="git log --oneline"
alias gs="git stash --include-untracked"
alias gsm="git stash push --include-untracked -m"
alias gsl="git stash list"
alias gsa="git stash apply"
alias gsp="git stash pop"
alias gsd="git stash drop"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gcom="git checkout master"
alias gcop="git checkout production"
alias yd="yarn dev"
alias yj="yarn test"
alias ygt="gac wip && yarn generate-types && grp"
alias gprm="git fetch origin master:master --update-head-ok && git rebase master"
alias grc="git rebase --continue"
alias gra="git rebase --abort"
alias gbs="git bisect start"
alias gbg="git bisect good"
alias gbb="git bisect bad"
alias gbr="git bisect reset"
alias gm="git merge"
alias gmm="git merge master"
alias gmp="git merge production"
alias gmc="git merge --continue"
alias gma="git merge --abort"
alias gpmm="git fetch origin master:master --update-head-ok && gmm"
alias gpmp="git fetch origin production:production --update-head-ok && gmp"
alias gmpr="gh pr review --comment -b 'SR' && gh pr merge --squash --delete-branch"

bindkey -v
bindkey "^H" backward-delete-char
bindkey "^?" backward-delete-char
KEYTIMEOUT=1
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

bindkey "^[k" history-beginning-search-backward-end
bindkey "^[j" history-beginning-search-forward-end
bindkey '^[l' autosuggest-accept
bindkey '^[h' forward-word

bindkey "^E" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end
bindkey '^Y' autosuggest-accept

function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';; # block
        viins|main) echo -ne '\e[5 q';; # beam
        esac
}

zle -N zle-keymap-select

zle-line-init() {
  echo -ne "\e[5 q"
}

zle -N zle-line-init

echo -ne '\e[5 q' # Use beam shape cursor on startup.

preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

function vi-yank-xclip {
    zle vi-yank
        echo "$CUTBUFFER" | wl-copy
}

zle -N vi-yank-xclip
bindkey -M vicmd 'y' vi-yank-xclip


gac() {
if [ -z "$1" ]; then
  git add --all && git commit
else
  git add --all && git commit -m "$1"
fi
}
gci() { git branch -D task#"$1"; }
gcoi() { git checkout task#"$1"; }
gacp() { git add --all && git commit -m "$1" && git push; }
gacpi() { git add --all && git commit -m "$1" && gpi; }
gpii() { git push -u origin HEAD && xdg-open "$(gh pr create --fill-first)/files" 1>/dev/null; }
open_issue() {
  BASE_BRANCH=$2
  BRANCH_NAME=task#"$1"
  git fetch origin $BASE_BRANCH:$BASE_BRANCH --update-head-ok && git checkout -b $BRANCH_NAME $BASE_BRANCH;
  git config branch.$BRANCH_NAME.description $BASE_BRANCH
}
goi() { open_issue $1 master; }
gopi() { open_issue $1 production; }
release_branch() {
  gh release view --json "targetCommitish" | jq .targetCommitish  | tr -d '"'
}
gcor() {
  git checkout $(release_branch)
}
gori() {
  open_issue $1 $(release_branch)
}
gpi() { git push -u origin HEAD && xdg-open "$(gh pr create --fill-first --base "$(git config branch.$(git rev-parse --abbrev-ref HEAD).description)" --body "Task ID [$(git rev-parse --abbrev-ref HEAD | cut -c 6-)]")/files" 1>/dev/null; }
gpid() { git push -u origin HEAD && xdg-open "$(gh pr create --draft --fill-first --base "$(git config branch.$(git rev-parse --abbrev-ref HEAD).description)" --body "Task ID [$(git rev-parse --abbrev-ref HEAD | cut -c 6-)]")/files" 1>/dev/null; }

npg() { nurl "$1" 2>/dev/null | sed -n 2,5p | wl-copy; }

export MANPAGER="nvim +Man!"
export MANWIDTH=999

eval "$(zoxide init zsh)"
source <(fzf --zsh)
