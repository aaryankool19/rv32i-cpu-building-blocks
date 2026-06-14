// reg_file.sv
// RV32I-style integer register file.
//
// A register file is a small storage block inside the CPU. Instructions read
// source values from it and write result values back into it.

module reg_file (
    input  logic        clk,
    input  logic        reset,
    input  logic        reg_write_en,
    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    // RV32I has 32 integer registers: x0 through x31.
    // Each register is 32 bits wide in RV32I.
    logic [31:0] registers [31:0];

    int i;

    // Writes happen on the rising edge of the clock.
    always_ff @(posedge clk) begin
        if (reset) begin
            // Clear all registers during reset.
            for (i = 0; i < 32; i++) begin
                registers[i] <= 32'h0000_0000;
            end
        end else if (reg_write_en && (rd_addr != 5'd0)) begin
            // x0 is hardwired to zero, so writes to x0 are ignored.
            registers[rd_addr] <= rd_data;
        end
    end

    // Reads are combinational: changing an address changes the read data
    // without waiting for a clock edge.
    //
    // x0 must always read as zero, even if something tried to write it.
    assign rs1_data = (rs1_addr == 5'd0) ? 32'h0000_0000 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'h0000_0000 : registers[rs2_addr];

endmodule
