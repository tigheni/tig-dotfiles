{pkgs}: let
  spotx = pkgs.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "d38a66e98dfa1289b4c0752ef40488aac07c9484";
    hash = "sha256-k04RQzP7+RGgtQyvuKiFCFBARynYWrGSYdgCMCvTpc0=";
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
