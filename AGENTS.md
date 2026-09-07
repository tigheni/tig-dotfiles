# Repository Guidelines

## Project Structure & Module Organization
This repository is a NixOS flake for the `nixos` host. The main entry points are `flake.nix` and `configuration.nix`. Host-specific or feature-specific Nix modules live in `hyprland/`, `zsh/`, `neovim/`, and `tmux/`. Editable application configs are stored in `config/` and symlinked into `~/.config` by `scripts/symlink-config.sh`. Runtime helpers and activation scripts live in `scripts/`. `hardware-configuration.nix` is machine-specific and should only change when the host hardware changes.

## Build, Test, and Development Commands
Use these from the repository root:

```bash
sudo nixos-rebuild switch --flake .#nixos
nixos-rebuild test --flake .#nixos
nix fmt
nix flake check
nix develop
```

`switch` applies the system configuration, `test` validates without making the new generation default, `fmt` formats Nix files, and `flake check` runs repository checks. Inside `nix develop`, run `shellcheck scripts/*.sh tmux/*.sh`, `statix check -i hardware-configuration.nix`, and `deadnix --fail --exclude hardware-configuration.nix` as needed.

## Coding Style & Naming Conventions
Follow existing Nix formatting conventions and keep changes aligned with `alejandra`. Use lowercase, descriptive filenames for scripts and modules, such as `tmux-output-nvim.sh` or `default.nix`. Keep shell scripts POSIX-compatible when practical and quote variables consistently. Avoid introducing new abstractions unless they match the current layout.

## Testing Guidelines
There is no dedicated unit test suite. Validation is done through Nix evaluation, `nix flake check`, and shell linting. Any changed shell script should pass `shellcheck`. When touching Nix modules, prefer `nixos-rebuild test --flake .#nixos` before `switch`.

## Commit & Pull Request Guidelines
Recent commits use short, imperative messages, often prefixed with `feat:` or `fix:`. Keep commits focused on one logical change. Pull requests should describe the system impact, list the commands you ran, and include screenshots only for visible desktop/UI changes. Mention any manual follow-up required after activation.

## Agent-Specific Instructions
Do not rewrite unrelated files or regenerate tracked outputs unless the task requires it. Be careful with `config/` entries that are intentionally skipped by activation, such as Nix-managed Neovim and Starship files. When changing wallpaper or Hyprland behavior, preserve the pattern of writing generated runtime config into `$XDG_RUNTIME_DIR` rather than modifying tracked files.
