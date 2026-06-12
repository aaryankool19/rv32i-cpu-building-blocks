// pc_reg.sv
// 32-bit Program Counter (PC) register.
//
// The PC stores the address of the instruction the CPU is currently using.
// This module only stores and updates the PC value. It does not decide where
// the next PC should come from.

module pc_reg (
    input  logic        clk,
    input  logic        reset,
    input  logic        pc_write_en,
    input  logic [31:0] pc_next,
    output logic [31:0] pc_current
);

    // Update the PC on the rising edge of the clock.
    always_ff @(posedge clk) begin
        if (reset) begin
            pc_current <= 32'h0000_0000;
        end else if (pc_write_en) begin
            pc_current <= pc_next;
        end else begin
            pc_current <= pc_current;
        end
    end

endmodule
