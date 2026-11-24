# Tang Nano 20K project template

Starting point for every lab in the course. Copy this folder, open it in VSCode (`File > Open Folder`) and work from there.

```
src/               design sources (*.sv); top module must be called `top`
tb/                testbenches, one per module: <name>_tb.sv
constraints/       pin constraints (.cst)
Makefile           build flow
.vscode/           tasks, recommended extensions
```

## Commands

| Command | Does |
|---|---|
| `make doctor` | checks tools and board connection |
| `make sim` | runs every testbench (`make sim TB=blink` for one) |
| `make wave` | opens the waveform (`make wave TB=blink`) |
| `make build` (or just `make`) | synthesis + place&route + bitstream (`build/top.fs`) |
| `make report` | resource usage and timing of the last build |
| `make prog` | loads the bitstream into SRAM (lost at power-off) |
| `make flash` | writes it to SPI flash (kept after power-off) |
| `make clean` | deletes `build/` |

In VSCode: `Ctrl+Shift+B` = build, `Terminal > Run Task...` for the rest.

The Makefile finds the OSS CAD Suite by itself (`$OSS_CAD_SUITE`, `C:/oss-cad-suite`, `~/oss-cad-suite`, `/opt/oss-cad-suite`), so you do not need to change your `PATH`. It needs GNU make (`winget install ezwinports.make` on Windows).

## Testbench convention

A testbench prints `PASS` and calls `$finish` when everything is correct and calls `$fatal` on the first error. `make sim` then stops with an error.

## LEDs

The six user LEDs are **active-low**: drive `0` to light one.
