{pkgs}:
# ArchEclipse's bar resource monitor. Upstream compiles sysmonitor.rs with rustc at
# runtime; building it here keeps rustc out of the user profile.
pkgs.runCommandCC "archeclipse-sysmonitor" {nativeBuildInputs = [pkgs.rustc];} ''
  mkdir -p $out/bin
  rustc --edition=2021 -O -o $out/bin/archeclipse-sysmonitor ${../config/quickshell/archeclipse/scripts/sysmonitor.rs}
''
