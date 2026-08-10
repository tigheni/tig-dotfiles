# tig-dotfiles

NixOS configuration and desktop dotfiles for the `nixos` host.

## Layout

- `flake.nix` / `configuration.nix` — NixOS entry points
- `packages.nix` — the single user package list
- `hyprland/`, `zsh/`, `neovim/`, `tmux/` — focused NixOS modules
- `config/` — editable application configuration, symlinked into `~/.config`
- `scripts/` — runtime helpers used by Hyprland and activation
- `hardware-configuration.nix` — machine-specific hardware settings

## Rebuild

From this directory:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

Useful recovery commands:

```bash
sudo nixos-rebuild test --flake .#nixos
sudo nixos-rebuild switch --rollback
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

The activation step symlinks entries from `config/` into `~/.config`. Existing files are preserved with timestamped `.bak` backups. Nix-managed Neovim and Starship files are intentionally skipped.

## Voxtype

Voxtype is installed from nixpkgs and runs as a user service. The Hyprland binding is push-to-talk:

- `Super+V` — hold to record, release to transcribe
- `Super+Shift+V` — open clipboard manager

After the first rebuild, download the model and verify the daemon:

```bash
voxtype setup --download
voxtype setup check
systemctl --user restart voxtype
voxtype status
```

## Checks

Format Nix files and run repository checks with:

```bash
nix fmt
nix flake check
```

Or enter the development shell, which provides `alejandra`, `shellcheck`, `statix`, and `deadnix`:

```bash
nix develop
shellcheck scripts/*.sh
statix check -i hardware-configuration.nix
deadnix --fail --exclude hardware-configuration.nix
```

## Design notes

Background services that have NixOS/systemd integration should be managed there. Hyprland `exec-once` is reserved for compositor-specific processes and GUI startup applications. Wallpaper selection writes its generated hyprpaper configuration to `$XDG_RUNTIME_DIR`, keeping tracked Hyprland files unchanged.
