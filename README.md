# opencode-extras

Personal collection of custom [OpenCode](https://opencode.ai) commands and modes, managed in a single repo and symlinked into `~/.config/opencode`.

## Structure

```
commands/   # Custom slash commands (.md files)
modes/      # Custom agent modes (.md files)
install.sh  # Symlinks files into ~/.config/opencode
remove.sh   # Removes those symlinks
```

## Usage

Clone this repo anywhere, then run the install script:

```sh
./install.sh
```

The script requires `~/.config/opencode` to already exist (i.e., opencode must be installed). It creates the `commands` and `modes` subdirectories as needed, then symlinks each file from this repo into the appropriate location. Running it again is safe — already-linked files are skipped.

To remove the symlinks:

```sh
./remove.sh
```

This only removes symlinks that point to files in this repo; any files that were not symlinked are left alone.
