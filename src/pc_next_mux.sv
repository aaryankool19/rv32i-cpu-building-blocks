// pc_next_mux.sv
// Chooses the next PC value.

module pc_next_mux (
    input  logic [31:0] pc_plus_4,
    input  logic [31:0] pc_target,
    input  logic        pc_src,
    output logic [31:0] pc_next
);

    // pc_src = 0: keep running normally with PC + 4.
    // pc_src = 1: use a target address.
    //
    // Later, pc_target can come from branch or jump logic.
    assign pc_next = pc_src ? pc_target : pc_plus_4;

endmodule
