#!/usr/bin/env bash
# setup-linux.sh - install and verify the course toolchain on linux.
# Usage: bash setup-linux.sh [options]     (bash setup-linux.sh --help lists them)
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup-unix.sh" --os linux "$@"
