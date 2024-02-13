final: prev: let
  spotx = prev.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "20e010e24bbac65d4b93b4e7d49865ad39e13402";
    sha256 = "sha256-/er3fq4s9rEZVi69rfZleDbpB2u580bxZPUgREJrdrc=";
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
