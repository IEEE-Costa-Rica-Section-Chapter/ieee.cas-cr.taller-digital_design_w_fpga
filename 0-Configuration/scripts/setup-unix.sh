#!/usr/bin/env bash
# setup-unix.sh - install and verify the course toolchain on Linux, WSL or macOS.
#
# Do not run this file directly unless you know your system: use the wrapper
#   setup-linux.sh   setup-wsl.sh   setup-macos.sh
#
# What it does (each step is skipped when it is already done, so it is safe to
# run again):
#   1. checks / installs the basic tools (make, curl, tar)
#   2. downloads the latest OSS CAD Suite and unpacks it in ~/oss-cad-suite
#   3. Linux only: installs a udev rule so the board is usable without root
#   4. installs the VSCode extensions (and VSCode itself on macOS with Homebrew)
#   5. verifies everything: copies project-template to a temporary folder and runs
#      `make doctor`, `make sim` and `make build` there
#
# It never edits your PATH or shell profile: the course Makefile finds the suite.
#
# Options
#   --suite-dir DIR   where to put the suite            (default: ~/oss-cad-suite)
#   --skip-vscode     do not touch VSCode
#   --skip-udev       Linux: do not install the udev rule
#   --skip-verify     do not run the final test build
#   --check           change nothing, only verify what is installed
#   --dry-run         print what would be done, change nothing
#   -h, --help        this text
#
# Environment: OSS_CAD_URL=<url of a .tgz>  use this download instead of asking
# GitHub for the latest release (useful behind a proxy or when GitHub's API rate
# limit is exhausted).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE="$REPO_DIR/project-template"
SUITE_DIR="$HOME/oss-cad-suite"
EXPECT_OS=""
SKIP_VSCODE=0
SKIP_UDEV=0
SKIP_VERIFY=0
CHECK_ONLY=0
DRY=0
EXTENSIONS="mshr-h.veriloghdl surfer-project.surfer"
RESULTS=""
FAILED=0

# ------------------------------------------------------------------ helpers
say()  { printf '%s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
note() { RESULTS="${RESULTS}$1|$2|$3
"; }
pass() { say "   [ok]   $1"; note "PASS" "$2" "$1"; }
skip() { say "   [skip] $1"; note "SKIP" "$2" "$1"; }
warn() { say "   [warn] $1"; note "WARN" "$2" "$1"; }
bad()  { say "   [FAIL] $1"; note "FAIL" "$2" "$1"; FAILED=1; }
have() { command -v "$1" >/dev/null 2>&1; }
run()  { if [ "$DRY" = 1 ]; then say "   (dry-run) $*"; return 0; fi; "$@"; }

as_root() {
  if [ "$(id -u)" = 0 ]; then "$@"
  elif have sudo; then sudo "$@"
  else say "   need root for: $*  (and sudo is not installed)"; return 1
  fi
}

usage() { sed -n '2,/^set -u/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

# --------------------------------------------------------------- arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --os) EXPECT_OS="$2"; shift ;;
    --suite-dir) SUITE_DIR="$2"; shift ;;
    --skip-vscode) SKIP_VSCODE=1 ;;
    --skip-udev) SKIP_UDEV=1 ;;
    --skip-verify) SKIP_VERIFY=1 ;;
    --check) CHECK_ONLY=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) say "unknown option: $1 (try --help)"; exit 2 ;;
  esac
  shift
done

# ------------------------------------------------------------ detect system
case "$(uname -s)" in
  Linux)  if grep -qi microsoft /proc/version 2>/dev/null; then OS=wsl; else OS=linux; fi ;;
  Darwin) OS=macos ;;
  *) say "Unsupported system: $(uname -s). On Windows use setup-windows.ps1."; exit 2 ;;
esac
case "$EXPECT_OS" in
  "") ;;
  macos) [ "$OS" = macos ] || { say "This is setup-macos.sh but you are on $OS. Use setup-$OS.sh."; exit 2; } ;;
  wsl)   [ "$OS" = wsl ]   || { say "This is setup-wsl.sh but this is not WSL (you are on $OS). Use setup-$OS.sh."; exit 2; } ;;
  linux) [ "$OS" = macos ] && { say "This is setup-linux.sh but you are on macOS. Use setup-macos.sh."; exit 2; } ;;
esac
ARCH="$(uname -m)"
case "$OS-$ARCH" in
  linux-x86_64|wsl-x86_64)   PLAT=linux-x64 ;;
  linux-aarch64|wsl-aarch64) PLAT=linux-arm64 ;;
  macos-arm64)               PLAT=darwin-arm64 ;;
  macos-x86_64)              PLAT=darwin-x64 ;;
  *) say "Unsupported combination: $OS / $ARCH"; exit 2 ;;
esac

say "Digital Design with FPGA - setup ($OS, $ARCH)"
say "  suite folder : $SUITE_DIR"
say "  course repo  : $REPO_DIR"
[ "$DRY" = 1 ] && say "  DRY RUN: nothing will be changed"
[ "$CHECK_ONLY" = 1 ] && say "  CHECK ONLY: nothing will be installed"
case "$SUITE_DIR" in *" "*) say "  warning: the suite path contains spaces; some tools mishandle that" ;; esac

# ------------------------------------------------- 1. basic tools (make...)
step "1/5 Basic tools"
if [ "$OS" = macos ] && ! xcode-select -p >/dev/null 2>&1; then
  if [ "$CHECK_ONLY" = 1 ] || [ "$DRY" = 1 ]; then
    bad "Xcode command line tools are missing (provide make)" "tools"
  else
    say "   Installing the Xcode command line tools (a window will ask for confirmation)..."
    xcode-select --install >/dev/null 2>&1
    say "   Finish that installation, then run this script again."
    exit 3
  fi
fi

MISSING=""
for t in make curl tar; do have "$t" || MISSING="$MISSING $t"; done
if [ -z "$MISSING" ]; then
  pass "make, curl and tar found ($(make --version 2>/dev/null | head -n 1))" "tools"
elif [ "$CHECK_ONLY" = 1 ]; then
  bad "missing:$MISSING" "tools"
elif [ "$OS" = macos ]; then
  bad "missing:$MISSING. Install the Xcode command line tools (xcode-select --install)" "tools"
else
  say "   missing:$MISSING - installing with the system package manager (may ask for your password)"
  if   have apt-get; then run as_root apt-get update && run as_root apt-get install -y make curl ca-certificates tar gzip
  elif have dnf;     then run as_root dnf install -y make curl tar gzip
  elif have pacman;  then run as_root pacman -S --noconfirm --needed make curl tar gzip
  elif have zypper;  then run as_root zypper --non-interactive install make curl tar gzip
  else say "   no supported package manager found (apt, dnf, pacman, zypper); install make, curl and tar yourself"
  fi
  MISSING=""
  for t in make curl tar; do have "$t" || MISSING="$MISSING $t"; done
  if [ -z "$MISSING" ] || [ "$DRY" = 1 ]; then pass "basic tools installed" "tools"; else bad "still missing:$MISSING" "tools"; fi
fi

# On macOS the system make is GNU Make 3.81 (2006). The course Makefile was
# written and tested with GNU Make 4.x.
if [ "$OS" = macos ] && have make; then
  MV="$(make --version 2>/dev/null | head -n 1 | sed 's/[^0-9]*\([0-9][0-9]*\).*/\1/')"
  if [ -n "$MV" ] && [ "$MV" -lt 4 ]; then
    if have gmake; then
      say "   note: system make is 3.x; gmake found. Use 'gmake' instead of 'make' in this course if make fails."
    elif have brew && [ "$CHECK_ONLY" = 0 ] && [ "$DRY" = 0 ]; then
      say "   system make is 3.x; installing GNU make 4 with Homebrew (it is called gmake)"
      brew install make >/dev/null 2>&1 && warn "installed gmake; if 'make' fails in a project, use 'gmake'" "make-version"
    else
      warn "system make is 3.x (untested with this course). 'brew install make' gives gmake (4.x)" "make-version"
    fi
  fi
fi

# ---------------------------------------------------- 2. OSS CAD Suite
step "2/5 OSS CAD Suite"
if [ -x "$SUITE_DIR/bin/yosys" ]; then
  pass "already installed in $SUITE_DIR" "suite"
elif [ "$CHECK_ONLY" = 1 ]; then
  bad "not found in $SUITE_DIR" "suite"
else
  URL="${OSS_CAD_URL:-}"
  if [ -z "$URL" ]; then
    say "   asking GitHub for the latest release..."
    URL="$(curl -fsSL -H 'User-Agent: ddfpga-setup' https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest 2>/dev/null \
           | grep -o "https://[^\"]*oss-cad-suite-$PLAT-[0-9]*\.tgz" | head -n 1)"
  fi
  if [ -z "$URL" ]; then
    bad "could not find the download URL (network, proxy or GitHub rate limit). Download oss-cad-suite-$PLAT-<date>.tgz from https://github.com/YosysHQ/oss-cad-suite-build/releases/latest and rerun with OSS_CAD_URL=<url>, or unpack it to $SUITE_DIR yourself" "suite"
  else
    say "   download: $URL"
    PARENT="$(dirname "$SUITE_DIR")"
    mkdir -p "$PARENT" 2>/dev/null
    FREE_KB="$(df -Pk "$PARENT" 2>/dev/null | awk 'NR==2{print $4}')"
    if [ -n "$FREE_KB" ] && [ "$FREE_KB" -lt 4000000 ]; then
      bad "less than 4 GB free in $PARENT" "suite"
    elif [ "$DRY" = 1 ]; then
      say "   (dry-run) would download (~0.5-0.7 GB) and unpack into $SUITE_DIR"
      skip "dry run" "suite"
    else
      TMP="$(mktemp -d "$PARENT/.ddfpga-XXXXXX")"
      if [ -t 1 ]; then PROG="--progress-bar"; else PROG="-sS"; say "   (no terminal: progress not shown, this takes a few minutes)"; fi
      if curl -fL $PROG --retry 3 -C - -o "$TMP/suite.tgz" "$URL" && tar -xzf "$TMP/suite.tgz" -C "$TMP"; then
        if [ -d "$TMP/oss-cad-suite" ]; then
          rm -rf "$SUITE_DIR"
          mv "$TMP/oss-cad-suite" "$SUITE_DIR"
          [ "$OS" = macos ] && xattr -dr com.apple.quarantine "$SUITE_DIR" 2>/dev/null
          if [ -x "$SUITE_DIR/bin/yosys" ]; then pass "installed in $SUITE_DIR" "suite"; else bad "unpacked, but $SUITE_DIR/bin/yosys is missing" "suite"; fi
        else
          bad "the archive did not contain an oss-cad-suite folder" "suite"
        fi
      else
        bad "download or unpack failed" "suite"
      fi
      rm -rf "$TMP"
    fi
  fi
fi

# ------------------------------------------------------- 3. USB access
step "3/5 USB access to the board"
RULE=/etc/udev/rules.d/99-tang-nano-20k.rules
if [ "$OS" = linux ]; then
  if [ "$SKIP_UDEV" = 1 ]; then
    skip "--skip-udev given" "udev"
  elif [ -f "$RULE" ]; then
    pass "udev rule already present ($RULE)" "udev"
  elif [ "$CHECK_ONLY" = 1 ]; then
    warn "udev rule missing: without it you need sudo to program the board" "udev"
  elif [ "$DRY" = 1 ]; then
    say "   (dry-run) would write $RULE and reload udev"; skip "dry run" "udev"
  else
    say "   installing $RULE (may ask for your password)"
    printf '%s\n' \
      '# Sipeed Tang Nano 20K (BL616 debugger): JTAG interface and serial port' \
      'SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", TAG+="uaccess"' \
      'SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", TAG+="uaccess"' \
      | as_root tee "$RULE" >/dev/null \
      && as_root udevadm control --reload-rules && as_root udevadm trigger \
      && pass "udev rule installed; unplug and replug the board" "udev" \
      || bad "could not install the udev rule (run with sudo rights, or program with sudo)" "udev"
  fi
elif [ "$OS" = wsl ]; then
  if command -v lsusb >/dev/null 2>&1 && lsusb | grep -qi "0403:6010"; then
    pass "the board is attached to WSL (usbipd). If programming fails with usb_open, run: sudo chmod a+rw /dev/bus/usb/<bus>/<device>" "udev"
  else
    warn "the board is not visible in WSL. To program from WSL share it with usbipd-win on Windows and attach it (step 0.4); needs the usbutils package for lsusb. Simulation and make build work without it." "udev"
  fi
else
  skip "macOS needs no driver or rule" "udev"
fi

# ------------------------------------------------------------ 4. VSCode
step "4/5 VSCode"
if [ "$SKIP_VSCODE" = 1 ]; then
  skip "--skip-vscode given" "vscode"
elif [ "$OS" = wsl ]; then
  skip "WSL: install VSCode on Windows plus its 'WSL' extension, then run 'code .' from here (step 0.2)" "vscode"
else
  if ! have code && [ "$OS" = macos ] && have brew && [ "$CHECK_ONLY" = 0 ] && [ "$DRY" = 0 ]; then
    say "   installing VSCode with Homebrew..."
    brew install --cask visual-studio-code >/dev/null 2>&1
    [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ] && PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
  fi
  if ! have code; then
    warn "'code' command not found. Install VSCode from https://code.visualstudio.com, then in VSCode run 'Shell Command: Install code command in PATH', or install the extensions by hand: $EXTENSIONS" "vscode"
  elif [ "$CHECK_ONLY" = 1 ]; then
    INSTALLED="$(code --list-extensions 2>/dev/null)"
    for e in $EXTENSIONS; do
      echo "$INSTALLED" | grep -qix "$e" && pass "extension $e present" "vscode" || warn "extension $e missing" "vscode"
    done
  else
    for e in $EXTENSIONS; do
      if [ "$DRY" = 1 ]; then say "   (dry-run) code --install-extension $e"
      elif code --install-extension "$e" >/dev/null 2>&1; then pass "extension $e installed" "vscode"
      else warn "could not install extension $e (search for it in the Extensions view)" "vscode"
      fi
    done
  fi
fi

# --------------------------------------------------------- 5. verification
step "5/5 Verification (test build of the course template)"
if [ "$SKIP_VERIFY" = 1 ] || [ "$DRY" = 1 ]; then
  skip "verification skipped" "verify"
elif [ ! -d "$TEMPLATE" ]; then
  bad "project-template not found at $TEMPLATE (run this script from the course repository)" "verify"
elif [ ! -x "$SUITE_DIR/bin/yosys" ]; then
  bad "cannot verify: the suite is not installed" "verify"
elif ! have make; then
  bad "cannot verify: make is missing" "verify"
else
  export OSS_CAD_SUITE="$SUITE_DIR"
  W="$(mktemp -d)"
  cp -R "$TEMPLATE/." "$W/" && rm -rf "$W/build"
  LOG="$W/verify.log"
  show_tail() { tail -n 12 "$1" | sed 's/^/        /'; }

  if (cd "$W" && make doctor) >"$LOG.doctor" 2>&1; then pass "make doctor: every tool prints its version" "doctor"; else bad "make doctor failed" "doctor"; show_tail "$LOG.doctor"; fi

  if (cd "$W" && make sim) >"$LOG.sim" 2>&1 && grep -q PASS "$LOG.sim"; then pass "make sim: testbench printed PASS" "sim"; else bad "make sim failed" "sim"; show_tail "$LOG.sim"; fi

  if (cd "$W" && make build) >"$LOG.build" 2>&1 && [ -s "$W/build/top.fs" ]; then
    pass "make build: bitstream created ($(wc -c < "$W/build/top.fs" | tr -d ' ') bytes)" "build"
    grep -E "LUT4|DFF|Max frequency" "$LOG.build" | sed 's/^Info:[[:space:]]*/        /; s/^[[:space:]]*/        /' | head -n 5
  else
    bad "make build failed" "build"; show_tail "$LOG.build"
  fi

  SCAN="$(cd "$W" && openFPGALoader --scan-usb 2>&1)"
  if echo "$SCAN" | grep -qi "0403"; then pass "board detected on USB" "board"
  else warn "no board detected (fine if it is not connected; see step 0.4 of Module 0)" "board"; fi
  rm -rf "$W"
fi

# -------------------------------------------------------------- summary
step "Summary"
printf '%s' "$RESULTS" | while IFS='|' read -r st key msg; do
  [ -n "$st" ] && printf '   %-5s %-12s %s\n' "$st" "$key" "$msg"
done
say ""
if [ "$FAILED" = 0 ]; then
  say "Result: everything required is OK."
  if [ "$SUITE_DIR" != "$HOME/oss-cad-suite" ]; then say "Because you used a custom folder, set OSS_CAD_SUITE=$SUITE_DIR in your shell profile."; fi
  say "Next: copy project-template to a short path, open it in VSCode and continue with step 0.5 of Module 0."
  exit 0
else
  say "Result: something failed. Fix the [FAIL] lines above (Module 0, step 0.7 lists common causes) and run the script again."
  exit 1
fi
