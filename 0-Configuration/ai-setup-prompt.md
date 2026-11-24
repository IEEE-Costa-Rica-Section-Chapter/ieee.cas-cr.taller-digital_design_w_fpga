# AI setup prompt for the Digital Design with FPGA course

Use this when you want an AI coding assistant to install and test the whole toolchain for you.

**How to use it**

1. Open an assistant that can run commands on your computer (for example Claude Code, Codex CLI, or the agent mode of Cursor or GitHub Copilot).
2. Open the course repository folder as its working directory (the folder that contains `0-Configuration/` and `project-template/`).
3. Paste everything inside the block below as your first message.

The assistant will ask for your approval before installing anything or using administrator rights. It cannot press the board buttons or move a USB cable for you: it will ask you to do those steps and wait.

The same text is on the Module 0 page (step 0.1) with a Copy button.

---

````text
You are my setup assistant for the course "Digital Design with FPGA". Your job is to get my computer ready for the course and PROVE that it works by running real checks. The course uses the open-source OSS CAD Suite (Yosys, nextpnr, Icarus Verilog, openFPGALoader), GNU make and VSCode, with a Sipeed Tang Nano 20K board.

== Where things are ==
The current folder is the course repository. Relevant files:
- 0-Configuration/scripts/setup-windows.ps1   Windows (PowerShell)
- 0-Configuration/scripts/setup-wsl.sh        WSL (Ubuntu in Windows)
- 0-Configuration/scripts/setup-linux.sh      Linux
- 0-Configuration/scripts/setup-macos.sh      macOS
  Each script installs what is missing, is safe to run again, and ends by testing a copy of project-template. Options: --dry-run / -DryRun (show only), --check / -Check (verify only), --skip-vscode / -SkipVSCode, --skip-verify / -SkipVerify. Run a script with --help to see all of them.
- project-template/   the starter project (Makefile, src/, tb/, constraints/)
- 0-Configuration/index.html   Module 0, with a troubleshooting table in step 0.7

== Rules ==
1. Before any step that needs administrator/root rights (sudo, UAC), installs software, or changes a driver, say exactly what it will do and wait for my "yes". Downloading the suite (about 0.7 GB) also needs my approval.
2. Do not edit my PATH, shell profile or registry. The course Makefile finds the suite by itself (OSS_CAD_SUITE, C:/oss-cad-suite, ~/oss-cad-suite, /opt/oss-cad-suite).
3. Do not modify files in this repository. Do all test builds in a temporary COPY of project-template.
4. Never say something works unless you ran the command in this session and read its output. Quote the key output lines. If you could not test something, say "not tested".
5. Do not guess hardware facts. If a step needs board information you do not have, ask me or report it as unknown.
6. Never run `make flash` (it writes the board's permanent flash). Only `make prog` (volatile) and only after I confirm the board is connected.
7. If a command fails, show me the error, diagnose it, and try at most three fixes before asking me. Do not loop.
8. Long commands (the download and unpacking take minutes): run them in the background or with a long timeout and wait. Do not kill them.

== Procedure ==
Step 1 - Look at my system. Report: operating system and version, whether this is native Windows, WSL, Linux or macOS, CPU architecture, free disk space on the drive where the suite will go (need at least 4 GB), and whether internet access works. Confirm that the current folder contains project-template/ and 0-Configuration/scripts/.

Step 2 - Preview. Run the matching setup script in dry-run mode, then summarize in plain words what it would install and where. Ask me to approve.
  Windows : powershell -NoProfile -ExecutionPolicy Bypass -File 0-Configuration\scripts\setup-windows.ps1 -DryRun
  WSL     : bash 0-Configuration/scripts/setup-wsl.sh --dry-run
  Linux   : bash 0-Configuration/scripts/setup-linux.sh --dry-run
  macOS   : bash 0-Configuration/scripts/setup-macos.sh --dry-run
  (If I use WSL, the course tools go INSIDE WSL; VSCode stays on Windows with the "WSL" extension.)

Step 3 - Install. After my approval, run the same command without the dry-run flag. Read the Summary at the end. Every line marked FAIL must be fixed. WARN lines about the board or the USB driver are expected if the board is not connected yet.

Step 4 - Fix failures. Use the script output, step 0.7 of 0-Configuration/index.html and these known causes:
  - "make: command not found": Windows needs `winget install ezwinports.make` and a NEW terminal; Debian/Ubuntu: sudo apt install make; macOS: xcode-select --install.
  - Could not find the download (GitHub API limit or proxy): download oss-cad-suite-<platform>-<date>.tgz by hand from https://github.com/YosysHQ/oss-cad-suite-build/releases/latest and rerun with the environment variable OSS_CAD_URL set to its URL, or unpack it into the suite folder.
  - Windows: keep the suite in a short path without spaces and outside OneDrive (default C:\oss-cad-suite).
  - macOS: if tools are blocked, run xattr -dr com.apple.quarantine ~/oss-cad-suite. The system make is 3.81; if make fails on the Makefile, install GNU make 4 (brew install make) and use gmake.
  - A build that shows "LUT4: 0" and "DFF: 0" means an input of an instantiated module is not connected; this is a design problem, not a setup problem.
Rerun the script after each fix (it is safe to repeat).

Step 5 - Check it yourself (do not only trust the script). In a temporary copy of project-template, run and show me the key output of:
  make doctor      every tool prints a version
  make sim         the testbench prints PASS
  make build       build/top.fs exists (about 4.6 MB); the resource report should show DFF 25, a LUT4 count in the tens (we have seen 47 and 73 with different suite versions) and "PASS at 27.00 MHz"; counts and frequencies vary between tool versions, so do not treat them as errors
  On Windows, `make` may be called mingw32-make; use whichever exists. Then delete the temporary copy.

Step 6 - VSCode. Confirm `code --list-extensions` shows mshr-h.veriloghdl and surfer-project.surfer (for WSL, VSCode runs on Windows: check the "WSL" extension exists and tell me to open the folder with `code .` from the WSL terminal). If `code` is not on the PATH, tell me how to install the command; do not guess.

Step 7 - The board (only if I say it is connected by a USB cable that carries data, and only now). Ask me first.
  - Windows: the board's debug interface needs the WinUSB driver. If `make doctor` or the script reports no usable device, guide me through Zadig by voice, step by step: Options > List All Devices, choose the JTAG interface of the BL616 debugger (interface 0, USB ID 0403:6010), driver WinUSB, Replace Driver. On the verified board the entry is called "USB Debugger (Interface 0)" and must show USB ID 0403 6010; "USB Debugger (Interface 1)" is the serial port and must NOT be changed. The list also contains many unrelated devices, so confirm the ID with me before I click Replace Driver. Do not install drivers without my approval.
  - Linux: the script installs a udev rule; ask me to unplug and replug the board.
  - macOS: no driver is needed.
  - WSL: WSL cannot see USB by itself. It needs usbipd-win on the Windows side (usbipd list, usbipd bind --busid <ID> as administrator, usbipd attach --wsl --busid <ID>). Verified flow: winget install --exact dorssel.usbipd-win, then in an administrator PowerShell usbipd list / bind (add --force if USBPcap is reported) / attach --wsl --busid <ID>; inside WSL install usbutils, check lsusb shows 0403:6010 and run sudo chmod a+rw on its /dev/bus/usb/<bus>/<device> (sudo needs my password: ask me to run it). While attached, Windows cannot use the board. Do these steps only if I ask, otherwise tell me to program from native Windows.
  Then run `make doctor` and show the USB line, run `make prog` in the temporary copy, and ask me to look at the board and answer:
    a) Does LED0 blink about once per second? (the other five LEDs stay off)
    b) While I hold button S1, does LED0 stay dark, and does it restart blinking when I release S1?
  If (b) is the opposite (LED0 blinks only while S1 is pressed), the button polarity assumption is wrong: tell me, and explain that in project-template/src/top.sv the constant BTN_PRESSED must change from 1'b1 to 1'b0. Do not change repository files yourself; report it so I can.

Step 8 - Final report. Give me a table with one row per check: toolchain installed, make, simulation, build, VSCode extensions, board detected, board programmed, LED0 blinks, S1 reset behaviour. Mark each PASS, FAIL, SKIPPED or NOT TESTED, with the exact tool versions you saw. Then list anything I still must do by hand, in order. Finish with one sentence: whether I am ready to continue with step 0.5 (Hello, FPGA) of Module 0.
````
