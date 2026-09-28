#!/usr/bin/env bash

set -euo pipefail

source_dir="@DOTFILES_DIR@/config"
destination_dir="@CONFIG_DIR@"
mkdir -p "$destination_dir"

if [ ! -d "$source_dir" ]; then
    printf 'ERROR: config directory does not exist: %s\n' "$source_dir" >&2
    exit 1
fi

shopt -s nullglob

for destination_file in "$destination_dir"/*; do
    if [ ! -L "$destination_file" ]; then
        continue
    fi

    current_link=$(readlink "$destination_file")
    case "$current_link" in
        "$source_dir"/*)
            if [ ! -e "$current_link" ]; then
                echo "🗑️  Removing stale config symlink $(basename "$destination_file")"
                rm "$destination_file"
            fi
            ;;
    esac
done

for file in "$source_dir"/*; do
    filename=$(basename "$file")
    destination_file="$destination_dir/$filename"

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
