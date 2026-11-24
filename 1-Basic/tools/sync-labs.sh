#!/usr/bin/env bash
# sync-labs.sh - copy the shared project files from project-template/ into every lab,
# so that Makefile, constraints and VSCode settings are identical everywhere.
# (The course checks this: check-labs.sh fails if a lab's Makefile differs.)
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$HERE/../../project-template"
for lab in "$HERE"/../labs/*/; do
  cp "$T/Makefile" "$lab/Makefile"
  mkdir -p "$lab/constraints" "$lab/.vscode"
  cp "$T/constraints/"*.cst "$lab/constraints/"
  cp "$T/.vscode/"* "$lab/.vscode/"
  cp "$T/.gitignore" "$lab/.gitignore"
  echo "synced $(basename "$lab")"
done
