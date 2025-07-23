final: prev: let
spotx = prev.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "d5a23bfc64d75979373c5fddc81641dabff051aa";
    hash = "sha256-gYr2b9oSOB/kuK6Em3T+gAALgzpRQxvSBJNWoaJ7yvg=";  };
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