source_dir=/home/tig/tig-dotfiles/config
destination_dir=/home/tig/.config

# List of configs that are managed by NixOS built-in modules and should be skipped
nix_managed_configs=("nvim" "starship.toml")

for file in "$source_dir"/*; do
    filename=$(basename "$file")
    destination_file="$destination_dir/$filename"

    # Skip NixOS-managed configs
    if [[ " ${nix_managed_configs[@]} " =~ " ${filename} " ]]; then
        echo "⏭️  Skipping $filename (managed by NixOS built-in modules)"
        continue
    fi

    if [ -e "$destination_file" ]; then
        if [ -L "$destination_file" ]; then
            current_link=$(readlink "$destination_file")
            if [ "$current_link" = "$file" ]; then
                echo "✓ $filename already correctly symlinked"
                continue
            else
                echo "⚠️  $filename exists but points to different location:"
                echo "   Current: $current_link"
                echo "   Target:  $file"
                echo "   Backing up and creating new symlink..."
                mv "$destination_file" "$destination_file.bak"
            fi
        else
            echo "⚠️  $filename exists as regular file/directory, backing up..."
            mv "$destination_file" "$destination_file.bak"
        fi
    fi

    echo "🔗 Creating symlink for $filename..."
    ln -s "$file" "$destination_file"
    echo "✅ Symlinked $filename"
done

echo "🎉 Symlink setup complete!"
