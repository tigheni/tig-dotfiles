{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    whitelist.url = "github:abdennourzahaf/whitelist";
  };

  outputs = {
    nixpkgs,
    whitelist,
    ...
  }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        whitelist = whitelist.packages.x86_64-linux.default;
      };
      modules = [./configuration.nix];
    };
  };
}
