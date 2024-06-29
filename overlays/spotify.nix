final: prev: let
  version = "1.0.3";
  spotify-adblock = prev.fetchurl {
    name = "spotify-adblock-${version}";
    url = "https://github.com/abba23/spotify-adblock/releases/download/v${version}/spotify-adblock.so";
    sha256 = "0jzd7ljaibab1hjrjfmrmszfc21mnbygx39mpsn33lqryzza9gh2";
  };
in {
  spotify = prev.spotify.overrideAttrs (oldAttrs: {
    installPhase = ''
      ${oldAttrs.installPhase}
      mkdir -p $out/lib
      cp ${spotify-adblock} $out/lib/spotify-adblock.so
      sed -i "s:^Exec=.*:Exec=env LD_PRELOAD=$out/lib/spotify-adblock.so spotify %U:" $out/share/applications/spotify.desktop
    '';
  });
}
