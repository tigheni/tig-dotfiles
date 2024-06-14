final: prev: let
  version = "1.0.3";
  spotify-adblock = prev.fetchurl {
    name = "spotify-adblock-${version}";
    url = "https://github.com/abba23/spotify-adblock/releases/download/v${version}/spotify-adblock.so";
    sha256 = "sha256-pOQVhDOPzqE/R15PYrMb8tKs68/W/vpbt1Jz+N15LJs=";
    downloadToTemp = true;
    recursiveHash = true;
    postFetch = ''
      mkdir -p $out/lib
      mv $downloadedFile $out/lib/spotify-adblock.so
    '';
  };
in {
  spotify = prev.spotify.overrideAttrs (prev: {
    installPhase =
      prev.installPhase
      + ''
        wrapProgram $out/share/spotify/spotify \
          --prefix LD_PRELOAD "${spotify-adblock}/lib/spotify-adblock.so"
      '';
  });
}