final: prev: let
  spotx = prev.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "1a8cefcd612ae0e11685e945606a65f66013daf3";
    hash = "sha256-OXjGshYYv2NXp/grTfC18GglPJuDqCPFjXwoA/XWLxo=";
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
