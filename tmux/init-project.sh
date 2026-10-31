#!/usr/bin/env bash
# Scaffold a direnv + flake dev shell in the current directory. Files that
# already exist are left alone; .direnv is appended to an existing .gitignore.

set -euo pipefail

# Pin the release the system runs, e.g. "26.05".
release=$(nixos-version | cut -d. -f1,2)

if [ -e .envrc ]; then
    echo ".envrc already exists, leaving it"
else
    echo "use flake" >.envrc
fi

if [ -e flake.nix ]; then
    echo "flake.nix already exists, leaving it"
else
    cat <<EOL >flake.nix
{
  inputs = {nixpkgs.url = "github:nixos/nixpkgs/nixos-${release}";};

  outputs = {nixpkgs, ...}: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config = {allowUnfree = true;};
    };
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        nodejs
        pnpm
      ];
    };
  };
}
EOL
fi

if ! grep -qxF .direnv .gitignore 2>/dev/null; then
    # Don't glue the entry onto a last line that lacks a newline.
    if [ -s .gitignore ] && [ -n "$(tail -c 1 .gitignore)" ]; then
        echo >>.gitignore
    fi
    printf '# direnv\n.direnv\n' >>.gitignore
fi

direnv allow
