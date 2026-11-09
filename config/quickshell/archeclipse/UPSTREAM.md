# Upstream

This directory is a modified copy of `.config/quickshell/archeclipse` from
[AymanLyesri/ArchEclipse](https://github.com/AymanLyesri/ArchEclipse) (GPL-3.0).

- Imported in `ee129ab` from upstream commit
  `996420e2e8ea24715c0f7bdc473aa2d56b86cb26` (2026-10-31). The import matched
  upstream file for file, minus its docs, Supabase server functions, profiler
  reports and editor/dev tooling.
- Everything after that is local. List the local changes with:

  ```bash
  git log --oneline ee129ab..HEAD -- config/quickshell/archeclipse
  ```

## Pulling upstream changes

See what upstream changed since the import, then port what is wanted by hand;
files removed or rewritten here will not merge cleanly.

```bash
git clone https://github.com/AymanLyesri/ArchEclipse /tmp/ArchEclipse
git -C /tmp/ArchEclipse log --oneline 996420e2..HEAD -- .config/quickshell/archeclipse
git -C /tmp/ArchEclipse diff 996420e2..HEAD -- .config/quickshell/archeclipse
```

Update the commit hash above after porting.
