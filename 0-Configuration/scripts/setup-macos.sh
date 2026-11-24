#!/usr/bin/env bash
# setup-macos.sh - install and verify the course toolchain on macos.
# Usage: bash setup-macos.sh [options]     (bash setup-macos.sh --help lists them)
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup-unix.sh" --os macos "$@"
