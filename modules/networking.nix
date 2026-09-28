_: {
  networking = {
    # Matches nixosConfigurations.nixos, which previously only lined up because
    # both sides happened to default to "nixos".
    hostName = "nixos";

    networkmanager = {
      enable = true;
      # insertNameservers places these *before* the DHCP-supplied resolver.
      # networking.nameservers appends after it, which left the router
      # answering every query first.
      insertNameservers = ["1.1.1.1" "8.8.8.8"];
    };

    firewall = {
      enable = true;
      allowedUDPPorts = [5353]; # mDNS
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
    };
  };
}
