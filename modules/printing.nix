{pkgs, ...}: let
  # Canon UFR II driver (Canon MF3010 on USB) with two FHS paths fixed up:
  # - the cnrsdrvufr2 helper reads /usr/share/cnpkbidir/*.xml (printer info)
  #   and fails with "Sent 0 bytes" when it is missing, so redirect it too.
  canon-ufr2 = pkgs.canon-cups-ufr2.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        substituteInPlace $out/bin/cnrsdrvufr2 \
          --replace-fail "NIX_REDIRECTS='" "NIX_REDIRECTS='/usr/share/cnpkbidir=$out/share/cnpkbidir:"
      '';
  });
in {
  services = {
    printing = {
      enable = true;
      drivers = [
        pkgs.gutenprint
        canon-ufr2
      ];
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  # - the helper also execs /usr/bin/cnjbigufr2 with a call libredirect does
  #   not intercept; without it the job hangs in cnpkmoduleufr2r forever.
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/cnjbigufr2 - - - - ${canon-ufr2}/bin/cnjbigufr2"
  ];
}
