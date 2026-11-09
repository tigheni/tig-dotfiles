# tig-dotfiles

NixOS configuration and desktop dotfiles for the `nixos` host.

## Layout

- `flake.nix` / `configuration.nix` — NixOS entry points
- `packages.nix` — the single user package list
- `hyprland/`, `zsh/`, `neovim/`, `tmux/` — focused NixOS modules
- `config/` — editable application configuration, symlinked into `~/.config`
- `scripts/` — runtime helpers used by Hyprland and activation
- `hardware-configuration.nix` — machine-specific hardware settings

## Fresh install

On a new NixOS install, as user `tig`:

```bash
nix-shell -p git --run 'git clone https://github.com/tigheni/tig-dotfiles ~/tig-dotfiles'
cd ~/tig-dotfiles
cp /etc/nixos/hardware-configuration.nix .   # only if the hardware changed
sudo nixos-rebuild switch --flake .#nixos --extra-experimental-features 'nix-command flakes'
```

The repository has to live at `~/tig-dotfiles`: `dotfilesDir` in `flake.nix` is where the `~/.config` symlinks and the script paths point. Log in on tty1 afterwards and Hyprland starts through UWSM.

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

The activation step symlinks entries from `config/` into `~/.config`. Existing files are preserved with timestamped `.bak` backups.

## Checks

Format Nix files and run repository checks with:

```bash
nix fmt
nix flake check
```

GitHub Actions runs `nix flake check` on every pull request and push to `master`, and opens a weekly pull request that updates `flake.lock`.

Or enter the development shell, which provides `alejandra`, `shellcheck`, `statix`, and `deadnix`:

```bash
nix develop
shellcheck scripts/*.sh tmux/*.sh
statix check -i hardware-configuration.nix
deadnix --fail --exclude hardware-configuration.nix
```

## Design notes

Hyprland is started by UWSM, which brings up `graphical-session.target` once the compositor is running. Background daemons (hypridle, polkit agent, flameshot, KDE Connect, night light, voxtype) are systemd user services bound to that target, so they restart on failure and stop with the session; check them with `systemctl --user status <name>`. Hyprland `exec-once` is reserved for the ArchEclipse shell and GUI startup applications. Wallpaper selection writes its generated hyprpaper configuration to `$XDG_RUNTIME_DIR`, keeping tracked Hyprland files unchanged.
