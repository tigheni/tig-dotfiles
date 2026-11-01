{pkgs}:
# Quickshell with Qt Multimedia on its QML and plugin paths, which the ArchEclipse
# config needs for video wallpapers and previews. Wraps the stock binaries
# instead of rebuilding Quickshell.
pkgs.symlinkJoin {
  name = "quickshell-with-multimedia";
  paths = [pkgs.quickshell];
  nativeBuildInputs = [pkgs.makeWrapper];
  postBuild = ''
    for bin in quickshell qs; do
      wrapProgram $out/bin/$bin \
        --prefix NIXPKGS_QT6_QML_IMPORT_PATH : ${pkgs.qt6.qtmultimedia}/lib/qt-6/qml \
        --prefix QT_PLUGIN_PATH : ${pkgs.qt6.qtmultimedia}/lib/qt-6/plugins
    done
  '';
}
