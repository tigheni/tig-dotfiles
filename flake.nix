{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    ...
  }: let
    system = "x86_64-linux";
    username = "tig";
    dotfilesDir = "/home/${username}/tig-dotfiles";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit username dotfilesDir;
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      modules = [./configuration.nix];
    };

    formatter.${system} = pkgs.alejandra;

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [alejandra deadnix shellcheck statix];
    };

    checks.${system}.shellcheck =
      pkgs.runCommand "dotfiles-shellcheck" {
        nativeBuildInputs = [pkgs.shellcheck];
      } ''
        shellcheck ${./scripts/night-light.sh} \
          ${./scripts/set-wallpaper.sh} \
          ${./scripts/switch-audio-output-simple.sh} \
          ${./scripts/symlink-config.sh} \
          ${./tmux/init-project.sh} \
          ${./tmux/tmux-new-repo.sh} \
          ${./tmux/tmux-output-nvim.sh} \
          ${./tmux/tmux-sessions-fzf.sh}
        touch $out
      '';
  };
}
