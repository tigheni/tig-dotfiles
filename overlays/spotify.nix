final: prev: let
  spotx = prev.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "5d0824b782680eeaccde2f449fe33b23df059a56";
    hash = "sha256-eXHW5ybtmWuj9XJ9IH5e4Zl8uXhLC2hgLAQgeeEqoYQ=";
  };
in {
  spotify = prev.spotify.overrideAttrs (prev: {
    buildInputs = [final.perl final.unzip final.zip];
    postInstall =
      (prev.postInstall or "")
      + ''
        cp ${spotx}/spotx.sh spotx.sh
        chmod +x spotx.sh
        bash spotx.sh -P $out/share/spotify/ -c
      '';
  });
}
