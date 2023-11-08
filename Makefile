# Licensed under the Creative Commons 1.0 Universal License (CC0), see LICENSE
# for details.
#
# Author: Robert Primas (rprimas 'at' proton.me, https://rprimas.github.io), Rishub Nagpal
#
# Makefile for running verilog test bench and optionally viewing wave forms
# in GTKWave.

VERSION ?= v1

ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

VERILATOR_FLAGS =
VERILATOR_FLAGS += --cc --exe --timing
VERILATOR_FLAGS += --build -j --main
VERILATOR_FLAGS += -Wno-unoptflat -Wno-timescalemod -Wno-implicit
ifdef VCD
VERILATOR_FLAGS += --trace
endif
ifdef FST
VERILATOR_FLAGS += --trace-fst
endif

VERILATOR_INCLUDES = -Irtl/includes
VERILATOR_DEFINES = -DCONFIG_V_FILE="\"config_$(VERSION).vh\""




SRCS = rtl/asconp.sv rtl/ascon_core_sca.sv rtl/dom_and.sv rtl/tb_sca.sv
TOP=tb

.PHONY: clean verilator
verilator:
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INCLUDES) $(VERILATOR_DEFINES) $(SRCS) --top $(TOP)
	./obj_dir/Vtb

wave: verilator
	gtkwave tb.vcd config.gtkw --rcvar 'fontname_signals Source Code Pro 12' --rcvar 'fontname_waves Source Code Pro 12'
iverilog:
	iverilog -g2012 -o tb -Irtl/includes rtl/tb.sv rtl/ascon_core.sv rtl/asconp.sv
	vvp tb
clean:
	rm -rf obj_dir/
	rm -f tb tb.vcd
