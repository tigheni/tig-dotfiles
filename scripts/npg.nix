{pkgs}:
pkgs.writeShellApplication {
  name = "npg";
  runtimeInputs = [pkgs.nix-prefetch-github];
  text = ''
    username_repo=''${1:19}
    username=''$(echo "$username_repo" | cut -d "/" -f 1)
    repo=''$(echo "$username_repo" | cut -d "/" -f 2)
    nix-prefetch-github "$username" "$repo" --nix | sed -n 5,8p | xsel -b
  '';
}
