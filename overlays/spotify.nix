final: prev: let
  spotx = prev.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "c3d5223b7e93604f8e893697a55edd2a507a28fc";
    hash = "sha256-/ZKlpta27fg4pmJdL5I/TsqvU26gdx+UmylnM/tL2y8=";
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
