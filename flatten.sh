#!/bin/bash

SRC_DIR="$(pwd)"
DST_DIR="tmp"

echo "[INFO] Flattening directory structure of $SRC_DIR into $DST_DIR"

# Create destination directory if it doesn't exist
mkdir -p "$DST_DIR"

sanitize_and_rename_filename() {
    local filepath="$1"
    local filename
    filename=$(basename "$filepath")
    local dirname
    dirname=$(dirname "$filepath")

    # Special handling for .env files and Dockerfiles
    if [[ $filename == .env* ]]; then
        filename="dotenv${filename#.env}.txt"
    elif [[ $filename == Dockerfile* ]]; then
        filename="${filename}.txt"
    fi

    # Sanitize the filename: replace any character not alphanumeric, dot, underscore, or hyphen with an underscore
    filename=$(echo "$filename" | sed -e 's/[^A-Za-z0-9._-]/_/g')

    # If it's a top-level file, return just the filename; otherwise, prefix with the directory path (with slashes replaced by underscores)
    if [[ "$dirname" == "." || "$dirname" == "$SRC_DIR" ]]; then
        echo "$filename"
    else
        echo "${dirname//\//_}_$filename"
    fi
}

SCRIPT_NAME=$(basename "$0")

# Use git ls-files to get a list of all tracked files.
# This gives us a whitelist of files to process (relative paths)
tracked_files=()
while IFS= read -r file; do
    tracked_files+=("$SRC_DIR/$file")
done < <(git ls-files)

src_file_count=${#tracked_files[@]}
echo "[INFO] Total tracked files: $src_file_count"

# Process each tracked file
for src_file in "${tracked_files[@]}"; do
    # Get the file's path relative to SRC_DIR
    rel_path="${src_file#$SRC_DIR/}"
    sanitized_path=$(sanitize_and_rename_filename "$rel_path")
    dst_file="${sanitized_path//\//_}"

    echo "[INFO] Processing: $src_file -> $DST_DIR/$dst_file"
    cp "$src_file" "$DST_DIR/$dst_file"
done

# Generate a snapshot of the project directory structure.
git ls-files > "$DST_DIR/PROJECT_DIRECTORY_STRUCTURE.txt"
