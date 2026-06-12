BUILD_DIR = build
SIM_FILE = $(BUILD_DIR)/tb_pc_path.vvp

SV_FILES = \
	src/pc_reg.sv \
	src/pc_plus4.sv \
	src/pc_next_mux.sv \
	tb/tb_pc_path.sv

.PHONY: sim clean

sim: $(SIM_FILE)
	vvp $(SIM_FILE)

$(SIM_FILE): $(SV_FILES)
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -o $(SIM_FILE) $(SV_FILES)

clean:
	rm -rf $(BUILD_DIR)
