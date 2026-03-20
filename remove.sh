#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG="${HOME}/.config/opencode"

remove_file() {
  local src_file="${SCRIPT_DIR}/$1"
  local dest_file="${OPENCODE_CONFIG}/$1"

  if [ -L "$dest_file" ]; then
    local target
    target="$(readlink "$dest_file")"
    if [[ "$target" == "${src_file}" ]]; then
      rm "$dest_file"
      echo "  removed: $1"
    else
      echo "  skipping (symlink points elsewhere): $1"
    fi
  elif [ -e "$dest_file" ]; then
    echo "  skipping (not a symlink): $1"
  else
    echo "  not found: $1"
  fi
}

remove_links() {
  local src_dir="${SCRIPT_DIR}/$1"
  local dest_dir="${OPENCODE_CONFIG}/$1"

  if [ ! -d "$src_dir" ] || [ ! -d "$dest_dir" ]; then
    return
  fi

  for src_file in "${src_dir}"/*; do
    [ -e "$src_file" ] || continue
    local filename
    filename="$(basename "$src_file")"
    local dest_file="${dest_dir}/${filename}"

    if [ -L "$dest_file" ]; then
      rm "$dest_file"
      echo "  removed: ${1}/${filename}"
    elif [ -e "$dest_file" ]; then
      echo "  skipping (not a symlink): ${1}/${filename}"
    else
      echo "  not found: ${1}/${filename}"
    fi
  done
}

echo "Removing opencode-extras symlinks..."
remove_links "commands"
remove_links "agents"
remove_links "skills"
remove_file "opencode.json"
echo "Done."
