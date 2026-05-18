{pkgs}: let
  spotx = pkgs.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "c9b506c7749f853c827b6d4bd1d57818f953f68d";
    hash = "sha256-zPWsENobV+THZr0XgaEQgcFUKMwXvCsa+wlW7NZ1w/g=";
  };
in
  pkgs.spotify.overrideAttrs (prev: {
    buildInputs = [pkgs.perl pkgs.unzip pkgs.zip pkgs.util-linux pkgs.curl];
    postInstall =
      (prev.postInstall or "")
      + ''
        bash ${spotx}/spotx.sh -P $out/share/spotify/ -c
      '';
  })
