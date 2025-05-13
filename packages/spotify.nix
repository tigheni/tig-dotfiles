{pkgs}: let
  spotx = pkgs.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "d5a23bfc64d75979373c5fddc81641dabff051aa";
    hash = "sha256-gYr2b9oSOB/kuK6Em3T+gAALgzpRQxvSBJNWoaJ7yvg=";
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
