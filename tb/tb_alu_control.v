`timescale 1ns/1ps

module tb_alu_control;
    reg [1:0] ALUop;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    wire [3:0] ALU_control;
    wire is_muldiv;
    wire [2:0] muldiv_op;

    alu_control uut (
        .ALUop(ALUop),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .ALU_control(ALU_control),
        .is_muldiv(is_muldiv),
        .muldiv_op(muldiv_op)
    );

    task check;
        input [1:0] op;
        input [6:0] opc;
        input [2:0] f3;
        input [6:0] f7;
        input [3:0] exp_ctrl;
        input exp_mul;
        input [2:0] exp_mulop;
        begin
            ALUop = op;
            opcode = opc;
            funct3 = f3;
            funct7 = f7;
            #1;
            if (ALU_control !== exp_ctrl || is_muldiv !== exp_mul || muldiv_op !== exp_mulop) begin
                $display("FAIL ALUCTRL got ctrl=%b mul=%b mulop=%b exp %b %b %b",
                         ALU_control, is_muldiv, muldiv_op, exp_ctrl, exp_mul, exp_mulop);
                $finish;
            end
        end
    endtask

    initial begin
        check(2'b00, 7'b0000011, 3'b000, 7'b0000000, 4'b0000, 1'b0, 3'b000);
        check(2'b01, 7'b1100011, 3'b000, 7'b0000000, 4'b0001, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b000, 7'b0000000, 4'b0000, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b000, 7'b0100000, 4'b0001, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b111, 7'b0000000, 4'b0010, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b110, 7'b0000000, 4'b0011, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b100, 7'b0000000, 4'b0100, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b001, 7'b0000000, 4'b0101, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b101, 7'b0000000, 4'b0110, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b101, 7'b0100000, 4'b0111, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b010, 7'b0000000, 4'b1000, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b011, 7'b0000000, 4'b1001, 1'b0, 3'b000);
        check(2'b10, 7'b0110011, 3'b000, 7'b0000001, 4'b0000, 1'b1, 3'b000);
        check(2'b10, 7'b0110011, 3'b100, 7'b0000001, 4'b0000, 1'b1, 3'b100);
        $display("ALU CONTROL TESTS PASSED");
        $finish;
    end
endmodule
