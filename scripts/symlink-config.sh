#!/usr/bin/env bash

set -euo pipefail

source_dir="@DOTFILES_DIR@/config"
destination_dir="@CONFIG_DIR@"
mkdir -p "$destination_dir"

# List of configs that are managed by NixOS built-in modules and should be skipped
readonly nix_managed_configs=("nvim" "starship.toml")
shopt -s nullglob

for file in "$source_dir"/*; do
    filename=$(basename "$file")
    destination_file="$destination_dir/$filename"

    # Skip NixOS-managed configs
    managed=false
    for managed_config in "${nix_managed_configs[@]}"; do
        if [[ "$filename" == "$managed_config" ]]; then
            managed=true
            break
        fi
    done

    if "$managed"; then
        echo "⏭️  Skipping $filename (managed by NixOS built-in modules)"
        continue
    fi

    if [ -e "$destination_file" ] || [ -L "$destination_file" ]; then
        if [ -L "$destination_file" ]; then
            current_link=$(readlink "$destination_file")
            if [ "$current_link" = "$file" ]; then
                echo "✓ $filename already correctly symlinked"
                continue
            else
                echo "⚠️  $filename exists but points to different location:"
                echo "   Current: $current_link"
                echo "   Target:  $file"
                backup="$destination_file.bak.$(date +%Y%m%d-%H%M%S)"
                echo "   Backing up to $backup and creating new symlink..."
                mv "$destination_file" "$backup"
            fi
        else
            backup="$destination_file.bak.$(date +%Y%m%d-%H%M%S)"
            echo "⚠️  $filename exists as regular file/directory, backing up to $backup..."
            mv "$destination_file" "$backup"
        fi
    fi

    echo "🔗 Creating symlink for $filename..."
    ln -s "$file" "$destination_file"
    echo "✅ Symlinked $filename"
done

echo "🎉 Symlink setup complete!"
