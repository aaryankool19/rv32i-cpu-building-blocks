// tb_instr_mem_hex.sv
// Testbench that proves instruction memory can load a hex program file.

`timescale 1ns/1ps

module tb_instr_mem_hex;

    logic [31:0] addr;
    logic [31:0] instr;

    int errors;

    instr_mem #(
        .DEPTH(256),
        .INIT_FILE("programs/simple_program.hex")
    ) u_instr_mem (
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
        $dumpfile("build/instr_mem_hex.vcd");
        $dumpvars(0, tb_instr_mem_hex);

        errors = 0;
        addr   = 32'b0;

        $display("Starting instruction memory hex load test...");

        check_instr("hex address 0 returns addi x5, x0, 10",
                    32'h0000_0000, 32'h00a0_0293);

        check_instr("hex address 4 returns addi x6, x0, 20",
                    32'h0000_0004, 32'h0140_0313);

        check_instr("hex address 8 returns add x7, x5, x6",
                    32'h0000_0008, 32'h0062_83b3);

        check_instr("hex address 12 returns nop",
                    32'h0000_000c, 32'h0000_0013);

        if (errors == 0) begin
            $display("========================================");
            $display("ALL INSTR_MEM HEX LOAD TESTS PASSED");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("INSTR_MEM HEX LOAD TESTS FAILED: %0d failed test(s)", errors);
            $display("========================================");
        end

        $finish;
    end

endmodule
