// tb_reg_file.sv
// Testbench for the RV32I-style register file.

`timescale 1ns/1ps

module tb_reg_file;

    logic        clk;
    logic        reset;
    logic        reg_write_en;
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    logic [31:0] rd_data;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    int failures;

    reg_file u_reg_file (
        .clk         (clk),
        .reset       (reset),
        .reg_write_en(reg_write_en),
        .rs1_addr    (rs1_addr),
        .rs2_addr    (rs2_addr),
        .rd_addr     (rd_addr),
        .rd_data     (rd_data),
        .rs1_data    (rs1_data),
        .rs2_data    (rs2_data)
    );

    // 10 ns clock period.
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic check_value(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string       message
    );
        begin
            if (actual !== expected) begin
                $display("FAIL: %s | expected 0x%08h, got 0x%08h",
                         message, expected, actual);
                failures++;
            end else begin
                $display("PASS: %s | value = 0x%08h", message, actual);
            end
        end
    endtask

    task automatic write_register(
        input logic [4:0]  addr,
        input logic [31:0] data
    );
        begin
            rd_addr      = addr;
            rd_data      = data;
            reg_write_en = 1'b1;
            @(posedge clk);
            #1;
            reg_write_en = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("build/reg_file.vcd");
        $dumpvars(0, tb_reg_file);

        failures     = 0;
        reset        = 1'b1;
        reg_write_en = 1'b0;
        rs1_addr     = 5'd0;
        rs2_addr     = 5'd0;
        rd_addr      = 5'd0;
        rd_data      = 32'h0000_0000;

        $display("Starting register file test...");

        // 1. Reset clears registers.
        @(posedge clk);
        #1;
        reset = 1'b0;

        rs1_addr = 5'd1;
        rs2_addr = 5'd2;
        #1;
        check_value(rs1_data, 32'h0000_0000, "reset clears x1");
        check_value(rs2_data, 32'h0000_0000, "reset clears x2");

        // 2. Write 32'h0000002A to x1 and read it back.
        $display("Writing 0x0000002A to x1...");
        write_register(5'd1, 32'h0000_002a);
        rs1_addr = 5'd1;
        #1;
        check_value(rs1_data, 32'h0000_002a, "read back x1");

        // 3. Write different values to x2 and x3.
        $display("Writing different values to x2 and x3...");
        write_register(5'd2, 32'h1111_2222);
        write_register(5'd3, 32'h3333_4444);

        // 4. Read x2 and x3 at the same time using both read ports.
        rs1_addr = 5'd2;
        rs2_addr = 5'd3;
        #1;
        check_value(rs1_data, 32'h1111_2222, "rs1 reads x2");
        check_value(rs2_data, 32'h3333_4444, "rs2 reads x3");

        // 5. Attempt to write 32'hFFFFFFFF to x0.
        $display("Trying to write 0xFFFFFFFF to x0...");
        write_register(5'd0, 32'hffff_ffff);

        // 6. Confirm x0 still reads as 0.
        rs1_addr = 5'd0;
        rs2_addr = 5'd0;
        #1;
        check_value(rs1_data, 32'h0000_0000, "x0 still reads zero on rs1");
        check_value(rs2_data, 32'h0000_0000, "x0 still reads zero on rs2");

        // 7. reg_write_en = 0 prevents a write.
        $display("Trying to write x4 while reg_write_en = 0...");
        rd_addr      = 5'd4;
        rd_data      = 32'h5555_aaaa;
        reg_write_en = 1'b0;
        @(posedge clk);
        #1;

        rs1_addr = 5'd4;
        #1;
        check_value(rs1_data, 32'h0000_0000, "reg_write_en = 0 blocks write to x4");

        if (failures == 0) begin
            $display("========================================");
            $display("REGISTER FILE TEST RESULT: PASS");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("REGISTER FILE TEST RESULT: FAIL (%0d failure(s))", failures);
            $display("========================================");
        end

        $finish;
    end

endmodule
