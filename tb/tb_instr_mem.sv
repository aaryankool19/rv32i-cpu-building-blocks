// tb_instr_mem.sv
// Testbench for the default hardcoded instruction memory contents.

`timescale 1ns/1ps

module tb_instr_mem;

    logic [31:0] addr;
    logic [31:0] instr;

    int errors;

    instr_mem u_instr_mem (
        .addr (addr),
        .instr(instr)
    );

    task automatic check_instr(
        input string       test_name,
        input logic [31:0] test_addr,
        input logic [31:0] expected
    );
        begin
            addr = test_addr;
            #1;

            if (instr !== expected) begin
                $display("FAIL: %s | addr = 0x%08h, expected 0x%08h, got 0x%08h",
                         test_name, test_addr, expected, instr);
                errors++;
            end else begin
                $display("PASS: %s | addr = 0x%08h, instr = 0x%08h",
                         test_name, test_addr, instr);
            end
        end
    endtask

    initial begin
        $dumpfile("build/instr_mem.vcd");
        $dumpvars(0, tb_instr_mem);

        errors = 0;
        addr   = 32'b0;

        $display("Starting instruction memory test...");

        check_instr("address 0 returns addi x5, x0, 10",
                    32'h0000_0000, 32'h00a0_0293);

        check_instr("address 4 returns addi x6, x0, 20",
                    32'h0000_0004, 32'h0140_0313);

        check_instr("address 8 returns add x7, x5, x6",
                    32'h0000_0008, 32'h0062_83b3);

        check_instr("address 12 returns nop",
                    32'h0000_000c, 32'h0000_0013);

        check_instr("unused address 16 returns nop",
                    32'h0000_0010, 32'h0000_0013);

        check_instr("misaligned address 5 maps to word index 1",
                    32'h0000_0005, 32'h0140_0313);

        check_instr("large out-of-range address returns nop",
                    32'hffff_fffc, 32'h0000_0013);

        if (errors == 0) begin
            $display("========================================");
            $display("ALL INSTR_MEM TESTS PASSED");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("INSTR_MEM TESTS FAILED: %0d failed test(s)", errors);
            $display("========================================");
        end

        $finish;
    end

endmodule
