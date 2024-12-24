{pkgs, ...}: {
  users.users.abdennour.packages = with pkgs; [
    (
      pkgs.python3Packages.buildPythonApplication
      {
        pname = "whitelist";
        version = "0.1.0";
        format = "other";

        propagatedBuildInputs = with pkgs; [
          python3Packages.selenium
          chromedriver
          chromium
        ];

        dontUnpack = true;
        installPhase = "install -Dm755 ${./whitelist.py} $out/bin/whitelist";
      }
    )
  ];
}
