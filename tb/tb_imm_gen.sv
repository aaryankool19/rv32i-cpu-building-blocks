// tb_imm_gen.sv
// Focused testbench for the RV32I immediate generator.

`timescale 1ns/1ps

module tb_imm_gen;

    logic [31:0] instr;
    logic [2:0]  imm_sel;
    logic [31:0] imm_out;

    logic [11:0] s_imm;
    logic [12:0] b_imm;
    logic [20:0] j_imm;

    int errors;

    localparam logic [2:0]
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_U = 3'b011,
        IMM_J = 3'b100;

    imm_gen u_imm_gen (
        .instr  (instr),
        .imm_sel(imm_sel),
        .imm_out(imm_out)
    );

    task automatic check_imm(
        input string       test_name,
        input logic [31:0] test_instr,
        input logic [2:0]  test_imm_sel,
        input logic [31:0] expected
    );
        begin
            instr   = test_instr;
            imm_sel = test_imm_sel;
            #1;

            if (imm_out !== expected) begin
                $display("FAIL: %s | expected 0x%08h, got 0x%08h",
                         test_name, expected, imm_out);
                errors++;
            end else begin
                $display("PASS: %s | imm_out = 0x%08h", test_name, imm_out);
            end
        end
    endtask

    initial begin
        $dumpfile("build/imm_gen.vcd");
        $dumpvars(0, tb_imm_gen);

        errors  = 0;
        instr   = 32'b0;
        imm_sel = 3'b0;

        $display("Starting immediate generator test...");

        // A. I-type positive immediate: instr[31:20] = 12'd10.
        instr = 32'b0;
        instr[31:20] = 12'd10;
        check_imm("I-type positive immediate +10",
                  instr, IMM_I, 32'd10);

        // B. I-type negative immediate: 12'hFFC is -4 in 12-bit signed form.
        instr = 32'b0;
        instr[31:20] = 12'hffc;
        check_imm("I-type negative immediate -4",
                  instr, IMM_I, 32'hffff_fffc);

        // C. S-type positive immediate: split imm[11:5] and imm[4:0].
        s_imm = 12'd20;
        instr = 32'b0;
        instr[31:25] = s_imm[11:5];
        instr[11:7]  = s_imm[4:0];
        check_imm("S-type positive immediate +20",
                  instr, IMM_S, 32'd20);

        // D. S-type negative immediate: 12'hFF8 is -8 in 12-bit signed form.
        s_imm = 12'hff8;
        instr = 32'b0;
        instr[31:25] = s_imm[11:5];
        instr[11:7]  = s_imm[4:0];
        check_imm("S-type negative immediate -8",
                  instr, IMM_S, 32'hffff_fff8);

        // E. B-type positive branch offset: bit 0 is always 0.
        b_imm = 13'd16;
        instr = 32'b0;
        instr[31]    = b_imm[12];
        instr[7]     = b_imm[11];
        instr[30:25] = b_imm[10:5];
        instr[11:8]  = b_imm[4:1];
        check_imm("B-type positive branch offset +16",
                  instr, IMM_B, 32'd16);

        // F. B-type negative branch offset: 13'h1FF0 is -16 in 13-bit form.
        b_imm = 13'h1ff0;
        instr = 32'b0;
        instr[31]    = b_imm[12];
        instr[7]     = b_imm[11];
        instr[30:25] = b_imm[10:5];
        instr[11:8]  = b_imm[4:1];
        check_imm("B-type negative branch offset -16",
                  instr, IMM_B, 32'hffff_fff0);

        // G. U-type immediate: upper bits pass through, lower 12 bits are zero.
        instr = 32'b0;
        instr[31:12] = 20'h12345;
        check_imm("U-type immediate 0x12345000",
                  instr, IMM_U, 32'h12345_000);

        // H. J-type positive jump offset: bit 0 is always 0.
        j_imm = 21'd32;
        instr = 32'b0;
        instr[31]    = j_imm[20];
        instr[19:12] = j_imm[19:12];
        instr[20]    = j_imm[11];
        instr[30:21] = j_imm[10:1];
        check_imm("J-type positive jump offset +32",
                  instr, IMM_J, 32'd32);

        // I. J-type negative jump offset: 21'h1FFFEC is -20 in 21-bit form.
        j_imm = 21'h1fffec;
        instr = 32'b0;
        instr[31]    = j_imm[20];
        instr[19:12] = j_imm[19:12];
        instr[20]    = j_imm[11];
        instr[30:21] = j_imm[10:1];
        check_imm("J-type negative jump offset -20",
                  instr, IMM_J, 32'hffff_ffec);

        // J. Invalid selection returns zero.
        instr = 32'hffff_ffff;
        check_imm("default invalid imm_sel",
                  instr, 3'b111, 32'b0);

        if (errors == 0) begin
            $display("========================================");
            $display("ALL IMM_GEN TESTS PASSED");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("IMM_GEN TESTS FAILED: %0d failed test(s)", errors);
            $display("========================================");
        end

        $finish;
    end

endmodule
