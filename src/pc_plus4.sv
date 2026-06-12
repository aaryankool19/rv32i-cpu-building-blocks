// pc_plus4.sv
// Computes the normal next PC value.

module pc_plus4 (
    input  logic [31:0] pc_current,
    output logic [31:0] pc_plus_4
);

    // RV32I instructions are usually 4 bytes, so normal execution moves PC by 4.
    assign pc_plus_4 = pc_current + 32'd4;

endmodule
