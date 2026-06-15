// instr_mem.sv
// Simple ROM-style instruction memory for an RV32I learning CPU.
//
// Instruction memory stores the program. The CPU gives it the current PC
// address, and this module returns the 32-bit instruction stored there.

module instr_mem #(
    parameter DEPTH = 256,
    parameter INIT_FILE = ""
)(
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    // Each memory entry is one 32-bit RV32I instruction.
    logic [31:0] memory [0:DEPTH-1];

    // The PC is a byte address, but this memory is indexed by 32-bit words.
    // RV32I instructions are 4 bytes wide, so dropping addr[1:0] converts:
    //
    // byte address 0  -> word index 0
    // byte address 4  -> word index 1
    // byte address 8  -> word index 2
    //
    // This is why the read logic uses addr[31:2].
    logic [31:0] word_index;

    int i;

    assign word_index = addr[31:2];

    initial begin
        // Fill unused instruction memory with a RISC-V nop:
        // addi x0, x0, 0
        for (i = 0; i < DEPTH; i++) begin
            memory[i] = 32'h0000_0013;
        end

        if (INIT_FILE != "") begin
            // Load one 32-bit instruction per line from a hex file.
            $readmemh(INIT_FILE, memory);
        end else begin
            // Small built-in example program.
            memory[0] = 32'h00a0_0293; // addi x5, x0, 10
            memory[1] = 32'h0140_0313; // addi x6, x0, 20
            memory[2] = 32'h0062_83b3; // add x7, x5, x6
            memory[3] = 32'h0000_0013; // nop: addi x0, x0, 0
        end
    end

    // Instruction fetch is combinational in this simple learning model.
    //
    // This module only stores and returns instruction bits. It does not decode
    // the instruction, execute it, or decide what the CPU should do next.
    always_comb begin
        if (word_index < DEPTH) begin
            instr = memory[word_index];
        end else begin
            // Out-of-range fetches safely return nop.
            instr = 32'h0000_0013;
        end
    end

endmodule
