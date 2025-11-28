GTE_SRCS := $(wildcard srcs/*.sv)
BRAM_SRCS := $(wildcard srcs/memory/*.v)
BUILD     := obj_dir
SIM_GTE  := $(BUILD)/Vtb_gte

.PHONY: all run sim_gte clean

$(SIM_GTE): tb/tb_gte.sv $(GTE_SRCS) $(BRAM_SRCS) | $(BUILD)
	@echo "[VERILATOR] Compile -> $@"
	verilator --sv --trace-vcd --binary -j 32 \
	--top-module tb_gte \
	-Mdir $(BUILD) \
	-Isrcs \
	tb/tb_gte.sv $(GTE_SRCS) $(BRAM_SRCS) \
	-Wno-WIDTHEXPAND -Wno-WIDTHTRUNC
	

$(BUILD):
	@mkdir -p $(BUILD)

sim_gte: $(SIM_GTE)
	@echo "[RUN] ./$(SIM_GTE)"
	./$(SIM_GTE)

all: run
run: sim_gte

clean:
	@echo "[CLEAN]"
	@rm -rf $(BUILD) *.vcd *.fst *.lxt *.lxt2 *.vcd.gz