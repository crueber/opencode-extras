#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG="${HOME}/.config/opencode"

if [ ! -d "$OPENCODE_CONFIG" ]; then
  echo "Error: ${OPENCODE_CONFIG} does not exist. Install opencode first."
  exit 1
fi

cleanup_stale_links() {
  local dest_dir="${OPENCODE_CONFIG}/$1"

  [ -d "$dest_dir" ] || return 0

  for dest_file in "${dest_dir}"/*; do
    [ -L "$dest_file" ] || continue
    local target
    target="$(readlink "$dest_file")"
    # Only touch symlinks that point into this repo
    [[ "$target" == "${SCRIPT_DIR}"/* ]] || continue
    if [ ! -e "$dest_file" ]; then
      rm "$dest_file"
      echo "  removed stale link: ${1}/$(basename "$dest_file")"
    fi
  done
}

link_file() {
  local src_file="${SCRIPT_DIR}/$1"
  local dest_file="${OPENCODE_CONFIG}/$1"

  [ -e "$src_file" ] || return 0

  if [ -L "$dest_file" ]; then
    local target
    target="$(readlink "$dest_file")"
    if [[ "$target" == "${src_file}" ]]; then
      echo "  already linked: $1"
    else
      rm "$dest_file"
      ln -s "$src_file" "$dest_file"
      echo "  relinked: $1"
    fi
  elif [ -e "$dest_file" ]; then
    echo "  skipping (file exists, not a symlink): $1"
  else
    ln -s "$src_file" "$dest_file"
    echo "  linked: $1"
  fi
}

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
      local file_target
      file_target="$(readlink "$dest_file")"
      if [[ "$file_target" == "${src_file}" ]]; then
        echo "  already linked: ${1}/${filename}"
      else
        rm "$dest_file"
        ln -s "$src_file" "$dest_file"
        echo "  relinked: ${1}/${filename}"
      fi
    elif [ -e "$dest_file" ]; then
      echo "  skipping (file exists, not a symlink): ${1}/${filename}"
    else
      ln -s "$src_file" "$dest_file"
      echo "  linked: ${1}/${filename}"
    fi
  done
}

echo "Installing opencode-extras symlinks..."
cleanup_stale_links "commands"
cleanup_stale_links "agents"
cleanup_stale_links "skills"
link_files "commands"
link_files "agents"
link_files "skills"
link_file "opencode.json"
echo "Done."
