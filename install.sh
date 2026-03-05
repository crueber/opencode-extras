#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG="${HOME}/.config/opencode"

if [ ! -d "$OPENCODE_CONFIG" ]; then
  echo "Error: ${OPENCODE_CONFIG} does not exist. Install opencode first."
  exit 1
fi

link_files() {
  local src_dir="${SCRIPT_DIR}/$1"
  local dest_dir="${OPENCODE_CONFIG}/$1"

  if [ ! -d "$src_dir" ]; then
    return
  fi

  mkdir -p "$dest_dir"

  for src_file in "${src_dir}"/*; do
    [ -e "$src_file" ] || continue
    local filename
    filename="$(basename "$src_file")"
    local dest_file="${dest_dir}/${filename}"

    if [ -L "$dest_file" ]; then
      echo "  already linked: ${1}/${filename}"
    elif [ -e "$dest_file" ]; then
      echo "  skipping (file exists, not a symlink): ${1}/${filename}"
    else
      ln -s "$src_file" "$dest_file"
      echo "  linked: ${1}/${filename}"
    fi
  done
}

echo "Installing opencode-extras symlinks..."
link_files "commands"
link_files "modes"
echo "Done."
