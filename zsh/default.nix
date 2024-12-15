{pkgs, ...}: {
  users.users.abdennour = {
    shell = pkgs.zsh;
  };

  programs.zsh = {
    enable = true;
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
      "SHARE_HISTORY"
    ];
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestions = {
      enable = true;
      strategy = ["history" "completion"];
      highlightStyle = "fg=245";
      extraConfig = {
        "ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE" = "20";
      };
    };
    promptInit = "eval \"$(starship init zsh)\"";
    interactiveShellInit = ''
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
      # bindkey '^O' forward-word

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
      gmp() { git push -u origin HEAD && xdg-open "$(gh pr create --fill-first)/files" 1>/dev/null; }

      npg() { nurl "$1" 2>/dev/null | sed -n 2,5p | wl-copy; }

      EDITOR="nvim"
      export MANPAGER="nvim +Man!"
      export MANWIDTH=999

      eval "$(zoxide init zsh)"
      source <(fzf --zsh)
    '';
    shellAliases = {
      # Check if git aliases or abbrs are better
      gaa = "git add --all";
      gc = "git commit";
      # gac = "gaa && gcm";
      gacpsc = "gaa && gcm 'Applied suggested changes' && gph";
      gcm = "git commit -m";
      # gacm = "gaa && gcm";
      gca = "git commit --amend --no-edit";
      gaca = "gaa && gca";
      gph = "git push";
      gpl = "git pull";
      grp = "git reset HEAD~1";
      grhh = "git reset HEAD --hard && git clean -fd";
      glo = "git log --oneline";
      gs = "git stash --include-untracked";
      gsm = "git stash push --include-untracked -m";
      gsl = "git stash list";
      gsa = "git stash apply";
      gsp = "git stash pop";
      gsd = "git stash drop";
      gco = "git checkout";
      gcob = "git checkout -b";
      gcom = "git checkout master";
      gcop = "git checkout production";
      yd = "yarn dev";
      yj = "yarn test";
      ygt = "gac wip && yarn generate-types && grp";
      gprm = "git fetch origin master:master --update-head-ok && git rebase master";
      grc = "git rebase --continue";
      gra = "git rebase --abort";
      gbs = "git bisect start";
      gbg = "git bisect good";
      gbb = "git bisect bad";
      gbr = "git bisect reset";
      gm = "git merge";
      gmm = "git merge master";
      gmp = "git merge production";
      gmc = "git merge --continue";
      gma = "git merge --abort";
      gpmm = "git fetch origin master:master --update-head-ok && gmm";
      gpmp = "git fetch origin production:production --update-head-ok && gmp";
      gmpr = "gh pr review --comment -b 'SR' && gh pr merge --squash --delete-branch";
      # clean-nix = "nix-env --delete-generations old ; nix-store --gc ; nix-collect-garbage -d ; nix-store --optimise";
      ns = "nix search nixpkgs";
    };
  };
}
