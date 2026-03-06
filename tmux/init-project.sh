echo "use flake" > .envrc

cat <<EOL > flake.nix
{
  inputs = {nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";};

  outputs = {nixpkgs, ...}: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config = {allowUnfree = true;};
    };
  in {
    devShell.x86_64-linux = pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs
        pnpm
      ];
    };
  };
}
EOL


cat <<EOL > .gitignore
# direnv
.direnv
EOL

direnv allow
