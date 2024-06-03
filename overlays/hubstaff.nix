final: prev: {
  hubstaff = prev.hubstaff.overrideAttrs (prev: {
    version = "1.6.23-5c646160";
    src = final.fetchurl {
      url = "https://hubstaff-production.s3.amazonaws.com/downloads/HubstaffClient/Builds/Release/1.6.23-5c646160/Hubstaff-1.6.23-5c646160.sh?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAXXZQ5SWWCBLCBQ7G%2F20240515%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240515T204847Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=ca7481f72e193db87d2f4dd340707f3cac2e5627ff383300245be6ee21f5eea4";
      sha256 = "sha256-kt2imtj8b331FYiVU6QCuz9Tzxk7Pfr3vj/8u5ovLnY=";
    };
    installPhase =
      ''
        mkdir x86
      ''
      + prev.installPhase
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