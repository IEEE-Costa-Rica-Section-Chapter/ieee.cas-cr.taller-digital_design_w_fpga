#!/usr/bin/env bash
# setup-wsl.sh - install and verify the course toolchain on wsl.
# Usage: bash setup-wsl.sh [options]     (bash setup-wsl.sh --help lists them)
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup-unix.sh" --os wsl "$@"
