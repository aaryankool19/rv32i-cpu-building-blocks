BUILD_DIR = build
PC_SIM_FILE = $(BUILD_DIR)/tb_pc_path.vvp
REG_SIM_FILE = $(BUILD_DIR)/tb_reg_file.vvp

PC_SV_FILES = \
	src/pc_reg.sv \
	src/pc_plus4.sv \
	src/pc_next_mux.sv \
	tb/tb_pc_path.sv

REG_SV_FILES = \
	src/reg_file.sv \
	tb/tb_reg_file.sv

.PHONY: sim sim_reg clean

sim: $(PC_SIM_FILE)
	vvp $(PC_SIM_FILE)

sim_reg: $(REG_SIM_FILE)
	vvp $(REG_SIM_FILE)

$(PC_SIM_FILE): $(PC_SV_FILES)
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -o $(PC_SIM_FILE) $(PC_SV_FILES)

$(REG_SIM_FILE): $(REG_SV_FILES)
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -o $(REG_SIM_FILE) $(REG_SV_FILES)

clean:
	rm -rf $(BUILD_DIR)
