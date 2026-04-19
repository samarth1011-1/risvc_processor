`timescale 1ns/1ps

module tb_decoder;

    reg [31:0] instr_input;
    reg [31:0] pc;

    wire [6:0] opcode;
    wire [4:0] rs1, rs2, rd;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] imm;

    decoder uut (
        .instr_input(instr_input),
        .pc(pc),
        .opcode(opcode),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct3(funct3),
        .funct7(funct7),
        .imm(imm)
    );

    task check;
        input [31:0] exp_imm;
        input [6:0] exp_opcode;
        begin
            if (imm !== exp_imm || opcode !== exp_opcode) begin
                $display("FAIL @ %0t | imm=%h (exp %h), opcode=%b (exp %b)",
                         $time, imm, exp_imm, opcode, exp_opcode);
                $stop;
            end else begin
                $display("PASS @ %0t", $time);
            end
        end
    endtask

    initial begin
        $dumpfile("decoder.vcd");
        $dumpvars(0, tb_decoder);

        pc = 0;

        instr_input = 32'b0000000_00011_00010_000_00001_0110011;
        #1;
        check(32'b0, 7'b0110011);

        instr_input = 32'b000000001010_00010_000_00001_0010011;
        #1;
        check(32'd10, 7'b0010011);

        instr_input = 32'b111111111111_00010_000_00001_0010011;
        #1;
        check(32'hFFFFFFFF, 7'b0010011);

        instr_input = 32'b0000000_00011_00010_010_01000_0100011;
        #1;
        check(32'd8, 7'b0100011);

        instr_input = 32'b0000000_00011_00010_000_00100_1100011;
        #1;
        check(32'd4, 7'b1100011);

        instr_input = 32'h12345037;
        #1;
        check(32'h12345000, 7'b0110111);

        instr_input = 32'b00000000000100000000000011101111;
        #1;
        if (imm == 0) begin
            $display("FAIL J-type imm");
            $stop;
        end

        instr_input = 32'hFFFFFFFF;
        #1;
        check(32'b0, instr_input[6:0]);

        $display("All tests passed.");
        $finish;
    end

endmodule