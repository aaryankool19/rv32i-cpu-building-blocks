// imm_gen.sv
// RV32I immediate generator.
//
// An "immediate" is a constant value stored directly inside an instruction.
// For example, an ADDI instruction can say "add register rs1 plus the constant
// 10" without needing to read that 10 from another register.

module imm_gen (
    input  logic [31:0] instr,
    input  logic [2:0]  imm_sel,
    output logic [31:0] imm_out
);

    // The future control unit will choose one of these values after it decodes
    // the instruction opcode. This module only extracts the requested immediate.
    localparam logic [2:0]
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_U = 3'b011,
        IMM_J = 3'b100;

    logic [31:0] imm_i;
    logic [31:0] imm_s;
    logic [31:0] imm_b;
    logic [31:0] imm_u;
    logic [31:0] imm_j;

    // Build each immediate format in a named wire-like signal first. This keeps
    // the case statement easy to read and gives waveform viewers useful names.
    assign imm_i = {{20{instr[31]}}, instr[31:20]};
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    assign imm_b = {{19{instr[31]}},
                    instr[31],
                    instr[7],
                    instr[30:25],
                    instr[11:8],
                    1'b0};
    assign imm_u = {instr[31:12], 12'b0};
    assign imm_j = {{11{instr[31]}},
                    instr[31],
                    instr[19:12],
                    instr[20],
                    instr[30:21],
                    1'b0};

    always_comb begin
        case (imm_sel)
            IMM_I: begin
                // I-type immediates use bits [31:20].
                //
                // Sign extension copies the sign bit into the upper bits.
                // This lets a small negative immediate become a correct
                // 32-bit negative number.
                imm_out = imm_i;
            end

            IMM_S: begin
                // S-type store immediates are split into two instruction fields.
                imm_out = imm_s;
            end

            IMM_B: begin
                // B-type branch offsets are also split up.
                //
                // The final 1'b0 is included because branch targets are aligned
                // to 2-byte boundaries, so bit 0 of the offset is always zero.
                imm_out = imm_b;
            end

            IMM_U: begin
                // U-type immediates already occupy the upper 20 bits.
                // The lower 12 bits are zeros.
                imm_out = imm_u;
            end

            IMM_J: begin
                // J-type jump offsets are split across the instruction.
                //
                // Like B-type, the final 1'b0 is present because jump targets
                // are aligned and the lowest offset bit is always zero.
                imm_out = imm_j;
            end

            default: begin
                // If the future control unit gives an invalid selection, return
                // zero instead of accidentally producing a stale immediate.
                imm_out = 32'b0;
            end
        endcase
    end

endmodule
