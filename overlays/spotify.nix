final: prev: let
  spotx = prev.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "49409482bcfc558208f992e3c86047c89532a5e8";
    hash = "sha256-aplhsn7nMwjpsXTiTDn5lEHkJIL1WzkXajeKu3qXcTk=";
  };
in {
  spotify = prev.spotify.overrideAttrs (prev: {
    buildInputs = [final.perl final.unzip final.zip final.util-linux final.curl];
    postInstall =
      (prev.postInstall or "")
      + ''
        bash ${spotx}/spotx.sh -P $out/share/spotify/ -c
      '';
  });
}