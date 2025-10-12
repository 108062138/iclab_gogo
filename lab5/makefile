H264_SRCS := $(wildcard srcs/*.v)
BRAM_SRCS := $(wildcard srcs/memory/*.v)
BUILD     := obj_dir
SIM_H264  := $(BUILD)/Vtb_h264

.PHONY: all run sim_h264 clean

$(SIM_H264): tb/tb_h264.sv $(H264_SRCS) $(BRAM_SRCS) | $(BUILD)
	@echo "[VERILATOR] Compile -> $@"
	verilator --sv --trace-vcd --binary -j 32 \
	--top-module tb_h264 \
	-Mdir $(BUILD) \
	-Isrcs \
	tb/tb_h264.sv $(H264_SRCS) $(BRAM_SRCS) \
	-Wno-WIDTHEXPAND -Wno-WIDTHTRUNC
	

$(BUILD):
	@mkdir -p $(BUILD)

sim_h264: $(SIM_H264)
	@echo "[RUN] ./$(SIM_H264)"
	./$(SIM_H264)

all: run
run: sim_h264

clean:
	@echo "[CLEAN]"
	@rm -rf $(BUILD) *.vcd *.fst *.lxt *.lxt2 *.vcd.gz