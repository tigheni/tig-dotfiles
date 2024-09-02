final: prev: let
  spotx = prev.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "49409482bcfc558208f992e3c86047c89532a5e8";
    hash = "sha256-aplhsn7nMwjpsXTiTDn5lEHkJIL1WzkXajeKu3qXcTk=";
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
