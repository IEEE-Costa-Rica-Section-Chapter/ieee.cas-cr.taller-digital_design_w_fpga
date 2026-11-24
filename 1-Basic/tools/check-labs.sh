#!/usr/bin/env bash
# check-labs.sh - verify every lab of Level 1 with the real tools.
#   For each lab:  1. the shared files are identical to project-template/
#                  2. with the student stubs, `make sim` MUST FAIL (a lab that
#                     passes before being solved is a broken lab)
#                  3. with the solutions copied in, `make sim` passes and
#                     `make build` produces a bitstream.
# Usage:  bash 1-Basic/tools/check-labs.sh [lab ...]        (default: all labs)
#         MAKE=mingw32-make bash ...                         (if make has another name)
# Needs the OSS CAD Suite (found via OSS_CAD_SUITE or the usual folders, like the Makefile does).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABS="$HERE/../labs"; SOL="$HERE/../solutions"; T="$HERE/../../project-template"
MAKE="${MAKE:-make}"
LIST="$*"; [ -z "$LIST" ] && LIST="$(cd "$LABS" && ls -d */ | tr -d /)"
FAIL=0
bad() { echo "   [FAIL] $1"; FAIL=1; }
ok()  { echo "   [ok]   $1"; }

for lab in $LIST; do
  echo "== $lab"
  L="$LABS/$lab"
  [ -d "$L" ] || { bad "no such lab"; continue; }
  # 1. shared files
  cmp -s "$T/Makefile" "$L/Makefile" && ok "Makefile identical to the template" || bad "Makefile differs from project-template (run tools/sync-labs.sh)"
  cmp -s "$T/constraints/tang_nano_20k.cst" "$L/constraints/tang_nano_20k.cst" && ok "constraints identical" || bad "constraints differ"

  W="$(mktemp -d)"; cp -R "$L/." "$W/"; rm -rf "$W/build"
  if [ -d "$SOL/$lab" ]; then
    # 2. stubs must fail
    if (cd "$W" && $MAKE sim) >"$W/stub.log" 2>&1; then bad "make sim PASSES on the unsolved stubs"; else ok "make sim fails on the stubs (as it must)"; fi
    # 3. solutions pass
    cp "$SOL/$lab/"*.sv "$W/src/"
    rm -rf "$W/build"
    if (cd "$W" && $MAKE sim) >"$W/sol.log" 2>&1 && ! grep -q "FATAL\|error" "$W/sol.log"; then ok "make sim passes with the solution ($(grep -c PASS "$W/sol.log") testbench(es) printed PASS)"; else bad "make sim FAILS with the solution"; tail -n 8 "$W/sol.log" | sed 's/^/        /'; fi
  else
    if (cd "$W" && $MAKE sim) >"$W/sol.log" 2>&1; then ok "make sim passes"; else bad "make sim fails"; tail -n 8 "$W/sol.log" | sed 's/^/        /'; fi
  fi
  if (cd "$W" && $MAKE build) >"$W/build.log" 2>&1 && [ -s "$W/build/top.fs" ]; then
    ok "make build: bitstream created"
    grep -E "LUT4:|DFF:" "$W/build.log" | sed 's/^Info:[[:space:]]*/        /; s/^[[:space:]]*/        /'
  else bad "make build FAILS"; tail -n 8 "$W/build.log" | sed 's/^/        /'; fi
  # lab-specific: the latch lab must be rejected by synthesis before it is fixed
  if [ "$lab" = latch ]; then
    W2="$(mktemp -d)"; cp -R "$L/." "$W2/"; rm -rf "$W2/build"
    if (cd "$W2" && $MAKE stat TOP=dec2) >"$W2/stat.log" 2>&1; then bad "make stat accepted the buggy decoder"; else grep -q "Latch inferred" "$W2/stat.log" && ok "make stat rejects the buggy decoder (Latch inferred)" || bad "make stat failed for another reason"; fi
    rm -rf "$W2"
  fi
  rm -rf "$W"
done
echo
[ "$FAIL" = 0 ] && echo "ALL LABS OK" || echo "SOME CHECKS FAILED"
exit $FAIL
