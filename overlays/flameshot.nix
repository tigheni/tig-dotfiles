final: prev: {
  flameshot = prev.flameshot.overrideAttrs (prev: {
    src = final.fetchFromGitHub {
      owner = "flameshot-org";
      repo = "flameshot";
      rev = "14a136777cd82ab70f42c13b4bc9418c756d91d2";
      hash = "sha256-xM99adstwfOOaeecKyWQU3yY0p65pQyFgoz7WJNra98=";
    };

    nativeBuildInputs = prev.nativeBuildInputs ++ [final.libsForQt5.kguiaddons];

    cmakeFlags = [
      "-DUSE_WAYLAND_CLIPBOARD=true"
      "-DUSE_WAYLAND_GRIM=true"
    ];
  });
}
