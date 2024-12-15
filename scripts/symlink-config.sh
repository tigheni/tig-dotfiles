source_dir=/home/abdennour/Projects/dotfiles/config
destination_dir=/home/abdennour/.config

for file in "$source_dir"/*; do
    filename=$(basename "$file")
    destination_file="$destination_dir/$filename"

    if [ -e "$destination_file" ]; then
        if [ -L "$destination_file" ] && [ "$(readlink "$destination_file")" == "$file" ]; then
            continue
        else
            mv "$destination_file" "$destination_file.bak"
        fi
    fi

    ln -s "$file" "$destination_file"
done
