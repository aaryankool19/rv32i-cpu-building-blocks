// tb_pc_path.sv
// Testbench for the simple Program Counter path.

`timescale 1ns/1ps

module tb_pc_path;

    logic        clk;
    logic        reset;
    logic        pc_write_en;
    logic        pc_src;
    logic [31:0] pc_target;
    logic [31:0] pc_current;
    logic [31:0] pc_plus_4;
    logic [31:0] pc_next;

    int failures;

    // Program Counter register.
    pc_reg u_pc_reg (
        .clk        (clk),
        .reset      (reset),
        .pc_write_en(pc_write_en),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    // Normal PC + 4 path.
    pc_plus4 u_pc_plus4 (
        .pc_current(pc_current),
        .pc_plus_4 (pc_plus_4)
    );

    // Next PC selection mux.
    pc_next_mux u_pc_next_mux (
        .pc_plus_4(pc_plus_4),
        .pc_target(pc_target),
        .pc_src   (pc_src),
        .pc_next  (pc_next)
    );

    // 10 ns clock period.
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Check the PC value and print a readable result.
    task automatic check_pc(input logic [31:0] expected, input string message);
        begin
            if (pc_current !== expected) begin
                $display("FAIL: %s | expected PC = 0x%08h, got PC = 0x%08h",
                         message, expected, pc_current);
                failures++;
            end else begin
                $display("PASS: %s | PC = 0x%08h", message, pc_current);
            end
        end
    endtask

    initial begin
        $dumpfile("build/pc_path.vcd");
        $dumpvars(0, tb_pc_path);

        failures    = 0;
        reset       = 1'b1;
        pc_write_en = 1'b1;
        pc_src      = 1'b0;
        pc_target   = 32'h0000_0000;

        $display("Starting PC path test...");

        // 1. Reset sends PC to 0.
        @(posedge clk);
        #1;
        check_pc(32'h0000_0000, "reset sends PC to 0");

        reset = 1'b0;

        // 2. Normal execution increments PC by 4 each cycle.
        @(posedge clk);
        #1;
        check_pc(32'h0000_0004, "normal execution increments to PC + 4");

        @(posedge clk);
        #1;
        check_pc(32'h0000_0008, "normal execution increments again");

        @(posedge clk);
        #1;
        check_pc(32'h0000_000c, "normal execution keeps stepping by 4");

        // 3. pc_write_en = 0 makes the PC hold its value.
        pc_write_en = 1'b0;
        @(posedge clk);
        #1;
        check_pc(32'h0000_000c, "pc_write_en = 0 holds the PC");

        // Re-enable writes so the PC can move again.
        pc_write_en = 1'b1;

        // 4. pc_src = 1 sends PC to a branch/jump target.
        pc_src    = 1'b1;
        pc_target = 32'h0000_0040;
        @(posedge clk);
        #1;
        check_pc(32'h0000_0040, "pc_src = 1 selects branch/jump target");

        // 5. After branch/jump target, pc_src = 0 continues PC + 4 execution.
        pc_src = 1'b0;
        @(posedge clk);
        #1;
        check_pc(32'h0000_0044, "after target, normal PC + 4 resumes");

        @(posedge clk);
        #1;
        check_pc(32'h0000_0048, "normal PC + 4 continues");

        if (failures == 0) begin
            $display("========================================");
            $display("PC PATH TEST RESULT: PASS");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("PC PATH TEST RESULT: FAIL (%0d failure(s))", failures);
            $display("========================================");
        end

        $finish;
    end

endmodule
