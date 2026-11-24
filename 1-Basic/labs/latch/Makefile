# Makefile - build flow for the Sipeed Tang Nano 20K (open-source toolchain)
#
#   make doctor        check tools and USB connection
#   make sim           run every testbench in tb/            (make sim TB=blink for one)
#   make wave          open the waveform of a testbench      (make wave TB=blink)
#   make build         synthesis + place&route + bitstream   (default target)
#   make report        show resource usage and timing of the last build
#   make stat          synthesis only: cell counts of any module (make stat TOP=adder8)
#   make prog          load the bitstream into SRAM (volatile)
#   make flash         write the bitstream to SPI flash (persistent)
#   make clean         delete build/
#
# Conventions
#   src/*.sv            design sources; the top module is named `top`
#   tb/<name>_tb.sv     testbench with a module named <name>_tb
#   constraints/*.cst   pin constraints (first file found is used)
#
# The recipes are single commands with no shell built-ins, so they run the same
# under Windows cmd.exe/PowerShell, Linux and macOS.

# ------------------------------------------------------------------ settings
# (comments live on their own lines: a trailing comment would add spaces to the value)
TOP     ?= top
# openFPGALoader board name
BOARD   := tangnano20k
# nextpnr device
DEVICE  := GW2AR-LV18QN88C8/I7
# nextpnr --vopt family and gowin_pack -d
FAMILY  := GW2A-18C
# yosys synth_gowin -family
YFAM    := gw2a
# timing target in MHz (27 MHz oscillator)
CLK_MHZ := 27

BUILD := build
SRC   := $(sort $(wildcard src/*.sv src/*.v))
TBS   := $(sort $(wildcard tb/*_tb.sv))
CST   := $(firstword $(wildcard constraints/*.cst))
TB_NAMES := $(patsubst %_tb,%,$(basename $(notdir $(TBS))))
TB    ?= $(firstword $(TB_NAMES))
BIT   := $(BUILD)/$(TOP).fs

# --------------------------------------------- locate the OSS CAD Suite (PATH)
# Use $(OSS_CAD_SUITE) if set, else the usual install folders. If none exists we
# rely on the tools already being on PATH.
ifeq ($(OS),Windows_NT)
  SHELL := cmd.exe                   # same behavior whether or not Git's sh is installed
  EXE := .exe
  SEP := ;
  CANDIDATES := $(OSS_CAD_SUITE) C:/oss-cad-suite C:/oss-cad-suite/oss-cad-suite
  RMBUILD := if exist $(BUILD) rmdir /s /q $(BUILD)
  SHOW    := type $(subst /,\,$(BUILD)/stat.txt)
  REPORT  := findstr /R "[0-9]/.*[0-9]% Max.frequency" $(subst /,\,$(BUILD)/nextpnr.log)
else
  EXE :=
  SEP := :
  CANDIDATES := $(OSS_CAD_SUITE) $(HOME)/oss-cad-suite /opt/oss-cad-suite
  RMBUILD := rm -rf $(BUILD)
  SHOW    := cat $(BUILD)/stat.txt
  REPORT  := grep -E "[0-9]/.*[0-9]%|Max frequency" $(BUILD)/nextpnr.log
endif
SUITE := $(firstword $(foreach d,$(CANDIDATES),$(if $(wildcard $(d)/bin/yosys$(EXE)),$(d))))
ifneq ($(SUITE),)
  export PATH := $(SUITE)/bin$(SEP)$(SUITE)/lib$(SEP)$(PATH)
endif

# ------------------------------------------------------------------- targets
.PHONY: all build sim wave prog flash clean doctor report stat
.SECONDARY:                          # keep intermediate files (e.g. build/*.vvp)

all: build

build: $(BIT)

$(BUILD)/:
	mkdir $(BUILD)

# 1. synthesis: SystemVerilog -> netlist of FPGA primitives
$(BUILD)/$(TOP).json: $(SRC) | $(BUILD)/
	yosys -q -l $(BUILD)/yosys.log -p "$(foreach f,$(SRC),read_verilog -sv $(f);) synth_gowin -top $(TOP) -family $(YFAM) -json $@"

# 2. place & route: netlist + pin constraints -> placed and routed design
$(BUILD)/$(TOP)_pnr.json: $(BUILD)/$(TOP).json $(CST)
	nextpnr-himbaechel --json $< --write $@ --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CST) --freq $(CLK_MHZ) --quiet --log $(BUILD)/nextpnr.log

# 3. bitstream
$(BIT): $(BUILD)/$(TOP)_pnr.json
	gowin_pack -d $(FAMILY) -o $@ $<
	@echo Resource usage and timing - full log in $(BUILD)/nextpnr.log
	@$(REPORT)

report:
	@$(REPORT)

# Synthesis only, for any module (needs no pins): how many LUT4 / flip-flops /
# carry cells does this design use?  Output: build/stat.txt
stat: $(SRC) | $(BUILD)/
	yosys -q -p "$(foreach f,$(SRC),read_verilog -sv $(f);) synth_gowin -top $(TOP) -family $(YFAM); tee -o $(BUILD)/stat.txt stat"
	@$(SHOW)

prog: $(BIT)
	openFPGALoader -b $(BOARD) $(BIT)

flash: $(BIT)
	openFPGALoader -b $(BOARD) -f $(BIT)

# ---------------------------------------------------------------- simulation
# make sim            all testbenches        make sim TB=blink   just tb/blink_tb.sv
# A testbench prints PASS, or calls $fatal (vvp then exits non-zero and make stops).
SIMS := $(if $(filter command line,$(origin TB)),$(TB),$(TB_NAMES))

sim: $(addprefix sim-,$(SIMS))

sim-%: $(BUILD)/%_tb.vvp
	cd $(BUILD) && vvp $*_tb.vvp

$(BUILD)/%_tb.vvp: tb/%_tb.sv $(SRC) | $(BUILD)/
	iverilog -g2012 -Wall -Wno-timescale -s $*_tb -o $@ $< $(SRC)

wave:
	surfer $(BUILD)/$(TB)_tb.vcd

# -------------------------------------------------------------------- utility
doctor:
	@echo OSS CAD Suite: $(if $(SUITE),$(SUITE),not found in the usual places - using PATH)
	yosys -V
	nextpnr-himbaechel --version
	openFPGALoader --Version
	@echo iverilog: $(wordlist 1,4,$(shell iverilog -V))
	@echo Scanning USB for the board...
	openFPGALoader --scan-usb

clean:
	$(RMBUILD)
