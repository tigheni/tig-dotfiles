final: prev: {
  flameshot = prev.flameshot.overrideAttrs (prev: {
    nativeBuildInputs = prev.nativeBuildInputs ++ [final.libsForQt5.kguiaddons];

    cmakeFlags = [
      "-DUSE_WAYLAND_CLIPBOARD=true"
      "-DUSE_WAYLAND_GRIM=true"
    ];
  });
}
