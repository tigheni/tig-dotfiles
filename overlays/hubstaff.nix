final: prev: {
  hubstaff = prev.hubstaff.overrideAttrs (prev: {
    installPhase =
      prev.installPhase
      + ''
        ln -s $opt/x86_64/HubstaffCLI.bin.x86_64 $out/bin/HubstaffCLI

        mkdir -p $out/share/applications
        cat <<INI > $out/share/applications/hubstaff.desktop
        [Desktop Entry]
        Encodig=UTF-8
        Value=1.0
        Type=Application
        Name=Hubstaff
        GenericName=Hubstaff
        Comment=Hubstaff
        Icon=$opt/x86_64/resources/Hubstaff.png
        Exec=$opt/x86_64/HubstaffClient.bin.x86_64 %u
        Categories=Utility;
        MimeType=x-scheme-handler/hubstaff
        Path=$opt/x86_64
        INI
      '';
  });
}
