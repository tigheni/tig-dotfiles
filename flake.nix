{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    llm-agents,
    ...
  }: let
    system = "x86_64-linux";
    username = "tig";
    dotfilesDir = "/home/${username}/tig-dotfiles";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    # Lint checks run over the whole flake source, so new scripts and modules
    # are covered without being listed here.
    lint = name: tool: script:
      pkgs.runCommand "dotfiles-${name}" {nativeBuildInputs = [tool pkgs.findutils];} ''
        cd ${self}
        ${script}
        touch $out
      '';
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit username dotfilesDir;
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        llm-agents = llm-agents.packages.${system};
      };

      modules = [./configuration.nix];
    };

    formatter.${system} = pkgs.alejandra;

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [alejandra deadnix shellcheck statix];
    };

    checks.${system} = {
      shellcheck = lint "shellcheck" pkgs.shellcheck ''
        find . -name '*.sh' -print0 | xargs -0 shellcheck
      '';
      statix = lint "statix" pkgs.statix "statix check --ignore hardware-configuration.nix -- .";
      deadnix = lint "deadnix" pkgs.deadnix "deadnix --fail --exclude ./hardware-configuration.nix .";
    };
  };
}
