echo "use nix" > .envrc

cat <<EOL > shell.nix
let
  pkgs = import <nixpkgs> {};
in
  pkgs.stdenv.mkDerivation {
    name = "";
    buildInputs = with pkgs; [
    ];
  }
EOL

direnv allow
