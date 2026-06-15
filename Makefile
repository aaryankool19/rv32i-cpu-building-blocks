BUILD_DIR = build
PC_SIM_FILE = $(BUILD_DIR)/tb_pc_path.vvp
REG_SIM_FILE = $(BUILD_DIR)/tb_reg_file.vvp
IMM_SIM_FILE = $(BUILD_DIR)/tb_imm_gen.vvp
INSTR_SIM_FILE = $(BUILD_DIR)/tb_instr_mem.vvp
INSTR_HEX_SIM_FILE = $(BUILD_DIR)/tb_instr_mem_hex.vvp

PC_SV_FILES = \
	src/pc_reg.sv \
	src/pc_plus4.sv \
	src/pc_next_mux.sv \
	tb/tb_pc_path.sv

REG_SV_FILES = \
	src/reg_file.sv \
	tb/tb_reg_file.sv

IMM_SV_FILES = \
	src/imm_gen.sv \
	tb/tb_imm_gen.sv

INSTR_SV_FILES = \
	src/instr_mem.sv \
	tb/tb_instr_mem.sv

INSTR_HEX_SV_FILES = \
	src/instr_mem.sv \
	tb/tb_instr_mem_hex.sv

.PHONY: sim sim_reg sim_imm sim_instr sim_instr_hex sim_all clean

sim: $(PC_SIM_FILE)
	vvp $(PC_SIM_FILE)

sim_reg: $(REG_SIM_FILE)
	vvp $(REG_SIM_FILE)

sim_imm: $(IMM_SIM_FILE)
	vvp $(IMM_SIM_FILE)

sim_instr: $(INSTR_SIM_FILE)
	vvp $(INSTR_SIM_FILE)

sim_instr_hex: $(INSTR_HEX_SIM_FILE)
	vvp $(INSTR_HEX_SIM_FILE)

sim_all: sim sim_reg sim_imm sim_instr sim_instr_hex

$(PC_SIM_FILE): $(PC_SV_FILES)
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -o $(PC_SIM_FILE) $(PC_SV_FILES)

$(REG_SIM_FILE): $(REG_SV_FILES)
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -o $(REG_SIM_FILE) $(REG_SV_FILES)

$(IMM_SIM_FILE): $(IMM_SV_FILES)
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -o $(IMM_SIM_FILE) $(IMM_SV_FILES)

$(INSTR_SIM_FILE): $(INSTR_SV_FILES)
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -o $(INSTR_SIM_FILE) $(INSTR_SV_FILES)

$(INSTR_HEX_SIM_FILE): $(INSTR_HEX_SV_FILES) programs/simple_program.hex
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -o $(INSTR_HEX_SIM_FILE) $(INSTR_HEX_SV_FILES)

clean:
	rm -rf $(BUILD_DIR)
